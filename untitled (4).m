function [isSuccess, user] = logIn()
    % Initialize outputs
    isSuccess = false;
    user = '';  % Default empty value
    
    % Load existing user data (or initialize if not found)
    if exist('listings.mat', 'file')
        load('listings.mat', 'userinfo');
        % Corrected field names (plural)
        usernames = {userinfo.Username};  % Convert to cell array if needed
        passwords = {userinfo.Password};  % Convert to cell array if needed
    else
        usernames = {};
        passwords = {};
    end

    % Get user input
    username = input('Enter your username: ', 's');
    password = input('Enter your password: ', 's');

    % Check if username exists
    userIndex = find(strcmp(usernames, username), 1);
    if ~isempty(userIndex)
        if strcmp(password, passwords{userIndex})
            disp('Login successful!');
            isSuccess = true;
            user = username;
        else
            disp('Incorrect password. Try again.');
            [isSuccess, user] = logIn();  % Recursive retry
        end
    else
        disp('Username not found. Would you like to sign up?');
        askSignUp = upper(input('Sign up now? (Y/N): ', 's'));
        
        if askSignUp == "Y"
            [isSuccess, user] = signUp();  % Call signUp if user agrees
        else
            disp('Login failed. Returning to login screen.');
            [isSuccess, user] = logIn();  % Recursive retry
        end
    end
end

function [isSuccess, user] = signUp()
    % Initialize outputs
    isSuccess = false;
    user = '';  % Default empty value
    
    % Load database (ensure listings.mat exists)
    if ~exist('listings.mat', 'file')
        error('Database not found. Run the database setup first.');
    end
    load('listings.mat', 'userinfo', 'listings');

    % Get user input
    disp('----- SIGN UP -----');
    name = input('First Name: ', 's');
    lastname = input('Last Name: ', 's');
    email = input('Email: ', 's');
    while ~contains(email, '@') || ~contains(email, '.com')
        disp('Invalid email, try again.')
        email = input('Email: ', 's');
    end
    username = input('Username: ', 's');
    password = input('Password: ', 's');
    confirmPassword = input('Confirm Password: ', 's');
    while ~strcmp(password, confirmPassword)
        disp('Error: Passwords do not match.');
        password = input('Password: ', 's');
        confirmPassword = input('Confirm Password: ', 's');
    end
    policy = upper(input('Agree to terms? (Y/N): ', 's'));

    % Validate
    if ~strcmp(password, confirmPassword)
        disp('Error: Passwords do not match.');
        return;
    end
    if policy ~= 'Y'
        disp('Error: You must agree to the terms.');
        return;
    end

    % Check for duplicates
    for i = 1:length(userinfo)
        if strcmp(username, userinfo(i).Username)
            disp('Error: Username already taken.');
            return;
        end
        if strcmp(email, userinfo(i).Email)
            disp('Error: Email already registered.');
            return;
        end
    end

    % Add new user
    newUser = struct(...
        'Name', name, ...
        'Lastname', lastname, ...
        'Email', email, ...
        'Username', username, ...
        'Password', password, ...
        'Valid', 'No', ...
        'PolicyAgreed', (policy == 'Y') ...
    );
    userinfo(end+1) = newUser;

    % Save and return success
    save('listings.mat', "listings", 'userinfo', '-v7.3');
    disp('Signup successful!');
    isSuccess = true;
    user = username;  % Only assigned when successful
end

function searchListings()
    % Load listings from file
    if ~exist('listings.mat', 'file')
        error('listing.mat file not found. Please add items first.');
    end
    
    load('listings.mat', 'listings');
    
    % Get user search query
    query = lower(input('\nEnter your search query: > ', 's'));
    
    % Initialize search parameters
    keywords = "";
    priceLimit = inf;
    location = "";
    conditionFilter = "";
    categoryFilter = "";
    
    % Parse condition filter if specified
    if contains(query, "in ") && contains(query, "condition")
        condStart = strfind(query, 'in ');
        condEnd = strfind(query, 'condition');
        conditionFilter = strtrim(extractBetween(query, condStart+3, condEnd-1));
        query = erase(query, ['in ' conditionFilter ' condition']);
    end
    
    % Parse category filter if specified
    if contains(query, "category ") || contains(query, "type ")
        if contains(query, "category ")
            [query, categoryFilter] = extractFilter(query, "category ");
        else
            [query, categoryFilter] = extractFilter(query, "type ");
        end
    end
    
    % Parse price limit and location if specified
    if contains(query, "under")
        parts = split(query, "under");
        keywords = strtrim(parts(1));
        remQuery = strtrim(parts(2));
        tokens = regexp(remQuery, '(\d+)', 'tokens');
        if ~isempty(tokens)
            priceLimit = str2double(tokens{1}{1});
        end
        
        if contains(remQuery, "near")
            locParts = split(remQuery, "near");
            location = strtrim(locParts(2));
        end
    elseif contains(query, "near")
        parts = split(query, "near");
        keywords = strtrim(parts(1));
        location = strtrim(parts(2));
    else
        keywords = strtrim(query);
    end
    
    % Display parsed search parameters
    fprintf('\nSearch Parameters:\n');
    fprintf('  Keywords: %s\n', char(keywords));
    fprintf('  Max Price: $%.2f\n', priceLimit);
    if ~isempty(location)
        fprintf('  Location: %s\n', char(location));
    end
    if ~isempty(conditionFilter)
        fprintf('  Condition: %s\n', char(conditionFilter));
    end
    if ~isempty(categoryFilter)
        fprintf('  Category: %s\n', char(categoryFilter));
    end
    
    % Initialize scores array
    scores = zeros(length(listings), 1);
    matchedItems = false(length(listings), 1);
    
    % Score each item based on search criteria
    for i = 1:length(listings)
        score = 0;
        
        % Check name/keyword match
        if contains(lower(listings(i).ItemName), keywords)
            score = score + 2;
        end
        
        % Check price limit
        if listings(i).Price <= priceLimit
            score = score + 1;
        end
        
        % Check location match
        if ~isempty(location) && contains(lower(listings(i).Location), location)
            score = score + 1;
        end
        
        % Check condition match
        if ~isempty(conditionFilter) && strcmpi(listings(i).Condition, conditionFilter)
            score = score + 1;
        end
        % Check category match (if field exists)
        if isfield(listings, 'Category') && ~isempty(categoryFilter) && ...
           contains(lower(listings(i).Category), lower(categoryFilter))
            score = score + 1;
        end
        scores(i) = score;
        matchedItems(i) = (score > 0);
    end
    
    % Filter and sort items
    if ~any(matchedItems)
        fprintf('No items match your search criteria.\n');
        return;
    end
    
    [~, idx] = sort(scores(matchedItems), 'descend');
    sortedItems = listings(matchedItems);
    sortedItems = sortedItems(idx);
    
    % Display search results
    fprintf('Found %d matching items:\n', length(sortedItems));
    for i = 1:length(sortedItems)
        fprintf('\nItem %d (Relevance: %d):\n', i, scores(idx(i)));
        fprintf('  Name: %s\n', sortedItems(i).ItemName);
        fprintf('  Price: $%.2f\n', sortedItems(i).Price);
        fprintf('  Condition: %s\n', sortedItems(i).Condition);
        fprintf('  Location: %s\n', sortedItems(i).Location);
        if isfield(sortedItems, 'Category')
            fprintf('  Category: %s\n', sortedItems(i).Category);
        end
        fprintf('  Seller: %s (Verified: %s)\n', ...
                sortedItems(i).UserName, sortedItems(i).Verified);
    end
end

function [remainingQuery, filterValue] = extractFilter(query, filterType)
    filterStart = strfind(query, filterType);
    remainingParts = strsplit(query(filterStart(1)+length(filterType):end));
    filterValue = remainingParts{1};
    remainingQuery = strtrim(strrep(query, [filterType filterValue], ''));
end

function sellItem()
    % Load existing listings or initialize properly
    if exist('listings.mat', 'file')
        load('listings.mat', 'listings', 'userinfo');
    else
        error("database not found!!")
    end
    
    % Get new item details with validation
    new_item.ItemName = input('Enter item name: ', 's');
    while isempty(new_item.ItemName)
        new_item.ItemName = input('Item name cannot be empty. Please enter item name: ', 's');
    end
    
    price_valid = false;
    while ~price_valid
        price_str = input('Enter price: ', 's');
        new_item.Price = str2double(price_str);
        if ~isnan(new_item.Price) && new_item.Price >= 0
            price_valid = true;
        else
            fprintf('Invalid price. Please enter a positive number.\n');
        end
    end
    
    new_item.Condition = upper(input('Enter condition (New/Used): ', 's'));
    while ~ismember(new_item.Condition, {'NEW', 'USED'})
        new_item.Condition = upper(input('Please enter either "New" or "Used": ', 's'));
    end
    
    new_item.Location = input('Enter location: ', 's');
    new_item.UserName = input('Enter your name: ', 's');
    
    new_item.Verified = upper(input('Is seller verified? (Yes/No): ', 's'));
    while ~ismember(new_item.Verified, {'YES', 'NO'})
        new_item.Verified = upper(input('Please enter either "Yes" or "No": ', 's'));
    end
    
    new_item.Category = input('Enter category: ', 's');
    
    % Ensure field order matches existing structure
    if ~isempty(listings)
        template = listings(1);
        for fn = fieldnames(template)'
            if ~isfield(new_item, fn{1})
                new_item.(fn{1}) = ''; % or appropriate default
            end
        end
        % Reorder fields to match existing structure
        new_item = orderfields(new_item, template);
    end
    
    % Add the new item properly
    if isempty(listings)
        listings = new_item;
    else
        listings(end+1) = new_item;
    end
    
    % Save the updated listings
    save('listings.mat', 'listings', 'userinfo');
    fprintf('Item "%s" added successfully!\n', new_item.ItemName);
end

function buyTransaction()    
    % Load listings database
    if ~exist('listings.mat', 'file')
        error('Database not found! Please create listings first.');
    end
    load('listings.mat', 'listings', 'userinfo');
    
    % Validate item selection
    while true
        buyer_choice = input('\nEnter the number of the item you want to purchase (or 0 to cancel): ');
        if buyer_choice == 0
            disp('Transaction cancelled.');
            return;
        elseif buyer_choice >= 1 && buyer_choice <= length(listings)
            break;
        else
            disp('Invalid selection. Please try again.');
        end
    end
    
    selected_item = listings(buyer_choice);
    fprintf('\nYou selected: %s ($%.2f)\n', selected_item.ItemName, selected_item.Price);
    
    % Contact seller simulation
    disp('\nContacting seller...');
    pause(1);
    fprintf('Message to %s: "Hi, is this %s still available?"\n', selected_item.UserName, selected_item.ItemName);
    pause(1);
    fprintf('Reply from %s: "Yes, it''s available!"\n', selected_item.UserName);
    
    % Price negotiation
    offerPrice = input('\nEnter your offer price: $');
    if offerPrice < selected_item.Price * 0.8  % 20% threshold for negotiation
        fprintf('Reply from %s: "Sorry, I can''t accept less than $%.2f"\n', selected_item.UserName, selected_item.Price*0.9);
        disp('Deal not accepted. Transaction ended.');
        return;
    elseif offerPrice < selected_item.Price
        fprintf('Reply from %s: "I can accept $%.2f"\n', selected_item.UserName, selected_item.Price*0.95);
        confirm = lower(input('Accept this price? (yes/no): ', 's'));
        if ~strcmp(confirm, 'yes')
            disp('Transaction cancelled.');
            return;
        end
        final_price = selected_item.Price*0.95;
    else
        final_price = selected_item.Price;
    end
    
    % Payment method selection
    fprintf('\nReply from %s: "Great! How will you be paying?"\n', selected_item.UserName);
    payment_method = lower(input('Enter payment method (cash/card): ', 's'));
    
    if strcmp(payment_method, 'cash')
        fprintf('\nReply from %s: "Here''s my contact: xxx-xxx-xxxx for pickup arrangements"\n', selected_item.UserName);
        disp('Transaction completed offline.');
    else
        % Process card payment
        disp('--- Payment Processing ---');
        
        % Validate card details
        while true
            card_name = input('Cardholder name: ', 's');
            if ~isempty(card_name), break; end
        end
        
        while true
            card_number = input('Card number (16 digits): ', 's');
            if length(card_number) == 16 && all(isstrprop(card_number, 'digit'))
                break;
            end
            disp('Invalid card number. Must be 16 digits.');
        end
        
        while true
            expiry = input('Expiry (MM/YY): ', 's');
            if length(expiry) == 5 && expiry(3) == '/'
                break;
            end
            disp('Invalid format. Use MM/YY.');
        end
        
        while true
            cvv = input('CVV (3 digits): ', 's');
            if length(cvv) == 3 && all(isstrprop(cvv, 'digit'))
                break;
            end
            disp('Invalid CVV. Must be 3 digits.');
        end
        
        % Process payment
        disp('Processing payment...');
        pause(2);
        
        % Generate receipt
        disp('--- TRANSACTION COMPLETE ---');
        fprintf('ITEM: %s\n', selected_item.ItemName);
        fprintf('SELLER: %s (%s)\n', selected_item.UserName, selected_item.Verified);
        fprintf('PRICE: $%.2f\n', final_price);
        fprintf('PAYMENT: %s ending in %s\n', upper(payment_method), card_number(end-3:end));
        fprintf('SHIPPING TO: %s\n', input('Enter your shipping address: ', 's'));
        disp('---------------------------');
        disp('Thank you for your purchase!');
        
        % Remove sold item from listings
        listings(buyer_choice) = [];
        save('listings.mat', 'listings', 'userinfo');
    end
end

function regTransation()
    disp("----- Transection Screen -----")
    % Enter payment information
    first_name = input('Enter your first name: ', 's');
    last_name = input('Enter your last name: ', 's');
    
    % Validate 16-digit credit card number
    while true
        payment_card = input('Enter a 16-digit credit card number: ', 's');
        if length(payment_card) == 16 && all(isstrprop(payment_card, 'digit'))
            break;
        else
            disp('Invalid card number. Please enter exactly 16 digits.');
        end
    end
    
    % Validate 3-digit CVV code
    while true
        cvv_code = input('Enter a 3-digit CVV code: ', 's');
        if length(cvv_code) == 3 && all(isstrprop(cvv_code, 'digit'))
            break;
        else
            disp('Invalid CVV. Please enter exactly 3 digits.');
        end
    end
    
    % Confirming the purchase
    disp('Processing transaction...');
    pause(2); % Simulate delay
    
    % Display order receipt
    disp('--- ORDER RECEIPT ---');
    fprintf('Order Name: %s %s Membership 1 Month: $5', first_name, last_name);
    disp('----------------------');
    
    disp('Thank you for using our marketplace!');   
end

function displayListings()
    % Load listings from file
    if ~exist('listings.mat', 'file')
        error('listings.mat file not found. Please add items first.');
    end
    
    load('listings.mat', 'listings');
    
    % Display header
    fprintf('\nCurrent Listings (%d items):\n', length(listings));
    fprintf('============================\n');
    
    % Display each listing
    for i = 1:length(listings)
        fprintf('\nITEM %d:\n', i);
        fprintf('  Name: %s\n', listings(i).ItemName);
        fprintf('  Price: $%.2f\n', listings(i).Price);
        fprintf('  Condition: %s\n', listings(i).Condition);
        fprintf('  Location: %s\n', listings(i).Location);
        
        % Optional fields (check if they exist)
        if isfield(listings, 'Category') && ~isempty(listings(i).Category)
            fprintf('  Category: %s\n', listings(i).Category);
        end
        
        fprintf('  Seller: %s', listings(i).UserName);
        if isfield(listings, 'Verified') && ~isempty(listings(i).Verified)
            fprintf(' (Verified: %s)', listings(i).Verified);
        end
        fprintf('\n');
    end
    
    fprintf('\n============================\n');
end

function verify = manageProfile(username)
    % Load user data with error handling
    try
        load('listings.mat', 'userinfo', 'listings')
        usernames = {userinfo.Username};  % Extract usernames
    catch
        error('Database file not found or corrupted!');
    end
    
    idx = find(strcmp(usernames, username));  % Get user index
    
    % Display profile info
    clc;  % Clear console for better readability
    disp('=== Welcome to Your Profile ===');
    fprintf('Username: %s\n', userinfo(idx).Username);
    fprintf('Password: ***********\n');
    fprintf('Verification Status: %s\n', userinfo(idx).Valid);

    % Display menu and handle input
    while true
        fprintf('Options:\n');
        fprintf('1 - Change Username\n');
        fprintf('2 - Change Password\n');
        fprintf('3 - Verify Account\n');
        fprintf('4 - Exit\n');
        
        option = input('Enter your choice (1-4): ', 's');
        
        switch option
            case '1'  % Change Username
                new_user = input('Enter new username: ', 's');
                updateUsername(username, new_user);
                username = new_user;  % Update username for current 
                verify = true;
            
            case '2'  % Change Password
                old_pass = input('Enter current password: ', 's');
                new_pass = input('Enter new password: ', 's');
                updatePassword(username, old_pass, new_pass);
                verify = true;
            
            case '3'  % Verify Account
                veri =  verifyAccount(username);
                verify = veri;
                if veri == false
                    return;
                end
            
            case '4'  % Exit
                disp('Exiting profile management.');
                verify = true;
                return;
            
            otherwise
                fprintf('Invalid option. Please enter 1, 2, 3, or 4.\n');
        end
        save('listing.m', 'userinfo', 'listings')
    end
end

function result = updateUsername(old_username, new_username)
    % Load the database
    load('listings.mat', 'listings', 'userinfo');
    
    % Check if the new username already exists
    all_usernames = {userinfo.Username};
    if any(strcmp(all_usernames, new_username))
        error('Username "%s" already exists! Choose a different one.', new_username);
    end
    
    % Find the user to update
    idx = find(strcmp(all_usernames, old_username));
    if isempty(idx)
        error('User "%s" not found!', old_username);
    end
    
    % Update the username
    userinfo(idx).Username = new_username;
    
    % Save changes
    save('listings.mat', 'listings', 'userinfo', '-append');
    fprintf('Username changed from "%s" to "%s".\n', old_username, new_username);
    result = true;
end

function success = updatePassword(username, old_password, new_password)
    % Load the database
    load('listings.mat', 'userinfo', 'listings');
    
    % Find the user by username (more secure than searching by password)
    all_usernames = {userinfo.Username};
    idx = find(strcmp(all_usernames, username));
    
    if isempty(idx)
        error('User "%s" not found!', username);
    end
    
    % Verify old password matches
    if ~strcmp(userinfo(idx).Password, old_password)
        error('Incorrect old password!');
    end
    
    % Check if new password is the same as the old one
    if strcmp(old_password, new_password)
        error('New password must be different from the old one!');
    end
    
    % Update the password
    userinfo(idx).Password = new_password;
    
    % Save changes
    save('listings.mat', 'listings', 'userinfo', '-append');
    fprintf('Password updated successfully for user "%s".\n', username);
    success = true;
end

function result = verifyAccount(username)
    % Load user database
    try
        load('listings.mat', 'userinfo', 'listings');
    catch
        error('Database file not found or corrupted!');
    end
    
    % Find the user index
    all_usernames = {userinfo.Username};
    idx = find(strcmp(all_usernames, username));
    
    % Check if user exists
    if isempty(idx)
        error('User "%s" not found!', username);
    end
    
    % Check verification status (case-insensitive)
    if strcmpi(userinfo(idx).Valid, "Yes")
        disp('Your account is already verified.');
        result = true;
        return;  % Exit early
    end
    
    % Generate and verify code
    random_num = randi([1000, 4000]);
    fprintf('Verification code: %d\n', random_num);
    
    % Input validation loop
    max_attempts = 3;save
    for attempt = 1:max_attempts
        check = input('Enter verification code: ', 's');  % 's' forces string input
        check = str2double(check);  % Convert to number
        
        if isnan(check) || ~isscalar(check)
            fprintf('Invalid input. Please enter a number.\n');
        elseif check == random_num
            userinfo(idx).Verified = "Yes";
            save('listings.mat', 'listings', 'userinfo', '-append');
            disp('Account successfully verified!');
            result = true;
            return;
        else
            fprintf('Incorrect code. Attempts left: %d\n', max_attempts - attempt);
        end
    end
    
    % If all attempts fail
    fprintf('Verification failed after %d attempts.', max_attempts);
    result = false;
    logout()
end

function logout()
    disp('You Are Logged Out.')
end

approve = false;
disp('Welcome to Mache Deux')
fprintf('1) Sign Up \n2) Log In\n')
choice = input('Enter your choice(1 or 2): ', 's');

switch choice
    case '1'
        [approve, currentuser] = signUp();
        regTransation()
    case '2'
        [approve, currentuser] = logIn();
    otherwise
        disp('Invalid choice:')
        fprintf('1) Sign Up \n2) Log In\n')
        choice = input('Enter your choice(1 or 2): ', 's');
end

if approve == true
    homechoice = 0;
    while ismember(homechoice, 0:4)
        disp("Home Page")
        pause(1)
        displayListings()
        pause(2)
        fprintf('1) Buy \n2) Sell \n3) Search Listing \n4) Profile \n5) Log out \n')
        homechoice = input('Enter your Choice: ');
        switch homechoice
            case 1
                buyTransaction()
            case 2
                sellItem()
            case 3
                searchListings()
            case 4
                result = manageProfile(currentuser);
                if result == false
                    logout()
                    return;
                end
            case 5
                logout()
            otherwise
                disp('Invaild Choice. Try again.')
                fprintf('1) Buy \n2) Sell \n3)Profile \n4)Log out \n')
                homechoice = input('Enter your Choice: ');
        end
    end
end