function success = logIn()
    % Load existing user data (or initialize if not found)
    if exist('listings.mat', 'file')
        load('listings.mat', 'userInfo');
        usernames = userInfo.Username;
        passwords = userInfo.Password;
    else
        error('Database not found!');
    end

    % Get user input
    username = input('Enter your username: ', 's');
    password = input('Enter your password: ', 's');
    

    % Check if username exists
    if ismember(username, usernames)
        idx = find(strcmp(usernames, username));
        if strcmp(password, passwords{idx})  % Use {} for cell array access
            disp('Login successful!');
            success = true;
        else
            disp('Incorrect password. Try again.');
            success = logIn();  % Recursive retry
        end
    else
        disp('Username not found. Would you like to sign up?');
        askSignUp = upper(input('Sign up now? (Y/N): ', 's'));
        
        if askSignUp == "Y"
            success = signUp();  % Call signUp if user agrees
        else
            disp('Login failed. Returning to login screen.');
            success = logIn();  % Recursive retry
        end
    end
end

%Profile Managing
function manageProfile(username)
    % Load user data with error handling
    try
        load('listings.mat', 'userInfo');
        usernames = {userInfo.Username};  % Extract usernames
    catch
        error('Database file not found or corrupted!');
    end

    % Check if user exists
    if ~ismember(username, usernames)
        error('User "%s" does not exist!', username);
    end
    
    idx = find(strcmp(usernames, username));  % Get user index
    
    % Display profile info
    clc;  % Clear console for better readability
    disp('=== Welcome to Your Profile ===');
    fprintf('Username: %s\n', userInfo(idx).Username);
    fprintf('Password: ***********\n');
    fprintf('Verification Status: %s\n\n', userInfo(idx).Verified);

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
                username = new_user;  % Update username for current session
            
            case '2'  % Change Password
                old_pass = input('Enter current password: ', 's');
                new_pass = input('Enter new password: ', 's');
                updatePassword(username, old_pass, new_pass);
            
            case '3'  % Verify Account
                verifyAccount(username);
            
            case '4'  % Exit
                disp('Exiting profile management.');
                return;
            
            otherwise
                fprintf('Invalid option. Please enter 1, 2, 3, or 4.\n');
        end
    end
end

%Changing username feature
function result = updateUsername(old_username, new_username)
    % Load the database
    load('listings.mat', 'userInfo');
    
    % Check if the new username already exists
    all_usernames = {userInfo.Username};
    if any(strcmp(all_usernames, new_username))
        error('Username "%s" already exists! Choose a different one.', new_username);
    end
    
    % Find the user to update
    idx = find(strcmp(all_usernames, old_username));
    if isempty(idx)
        error('User "%s" not found!', old_username);
    end
    
    % Update the username
    userInfo(idx).Username = new_username;
    
    % Save changes
    save('listings.mat', 'userInfo', '-append');
    fprintf('Username changed from "%s" to "%s".\n', old_username, new_username);
    result = true;
end

%changing password feature
function success = updatePassword(username, old_password, new_password)
    % Load the database
    load('listings.mat', 'userInfo');
    
    % Find the user by username (more secure than searching by password)
    all_usernames = {userInfo.Username};
    idx = find(strcmp(all_usernames, username));
    
    if isempty(idx)
        error('User "%s" not found!', username);
    end
    
    % Verify old password matches
    if ~strcmp(userInfo(idx).Password, old_password)
        error('Incorrect old password!');
    end
    
    % Check if new password is the same as the old one
    if strcmp(old_password, new_password)
        error('New password must be different from the old one!');
    end
    
    % Update the password
    userInfo(idx).Password = new_password;
    
    % Save changes
    save('listings.mat', 'userInfo', '-append');
    fprintf('Password updated successfully for user "%s".\n', username);
    success = true;
end

%Verify system
function result = verifyAccount(username)
    % Load user database
    try
        load('listings.mat', 'userInfo');
    catch
        error('Database file not found or corrupted!');
    end
    
    % Find the user index
    all_usernames = {userInfo.Username};
    idx = find(strcmp(all_usernames, username));
    
    % Check if user exists
    if isempty(idx)
        error('User "%s" not found!', username);
    end
    
    % Check verification status (case-insensitive)
    if strcmpi(userInfo(idx).Verified, "Yes")
        disp('Your account is already verified.');
        result = true;
        return;  % Exit early
    end
    
    % Generate and verify code
    random_num = randi([1000, 4000]);
    fprintf('Verification code: %d\n', random_num);
    
    % Input validation loop
    max_attempts = 3;
    for attempt = 1:max_attempts
        check = input('Enter verification code: ', 's');  % 's' forces string input
        check = str2double(check);  % Convert to number
        
        if isnan(check) || ~isscalar(check)
            fprintf('Invalid input. Please enter a number.\n');
        elseif check == random_num
            userInfo(idx).Verified = "Yes";
            save('listings.mat', 'userInfo', '-append');
            disp('Account successfully verified!');
            result = true;
            return;
        else
            fprintf('Incorrect code. Attempts left: %d\n', max_attempts - attempt);
        end
    end
    
    % If all attempts fail
    error('Verification failed after %d attempts.', max_attempts);
end


end
        
function appr_decl = signUp()
    % Load existing data (or initialize if file doesn't exist)
    if exist('listings.mat', 'file')
        load('listings.mat', 'userInfo'); % Load the struct
    else
        userInfo = struct('usernames', {{}}, 'passwords', {{}}); % Initialize empty struct
    end

    % Get user input
    username = input('Enter your username: ', 's');
    password = input('Enter your password: ', 's');
    confPassword = input('Re-enter your password: ', 's');
    policyConf = upper(input('I agree to the terms and conditions (Y/N): ', 's'));

    % Check agreement first
    if policyConf ~= "Y"
        disp('You must agree to the terms to register.');
        appr_decl = false;
        return; % Exit early
    end

    % Check password match
    if ~strcmp(password, confPassword)
        disp('Passwords do not match. Try again.');
        appr_decl= signUp(); % Recursive retry
        return;
    end

    % Check if username exists
    if ismember(username, userInfo.Username)
        disp('Username already exists. Please try another.');
        appr_decl = signUp(); % Recursive retry
        return;
    end

    % Add new user
    userInfo.Username{end+1} = username; % Append to cell array
    userInfo.Password{end+1} = password;
    userInfo.Verified{end+1} = "No";
    appr_decl = true;

    % Save updated struct
    save('listings.mat', 'userInfo');
    disp('Registration successful!');
end

function searchListings()
    % Load listings from file
    if ~exist('listings.mat', 'file')
        error('listing.mat file not found. Please add items first.');
    end
    
    load('listings.mat', 'listings');
    
    % Get user search query
    query = lower(input('\nEnter your search query:\n> ', 's'));
    
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
    fprintf('\n');
    
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


function addItemToListings()
    % Load existing listings or create new file
    if exist('listings.mat', 'file')
        load('listings.mat', 'listings');
    else
        listings = struct('ItemName', {}, 'Price', {}, 'Condition', {}, ...
                         'Location', {}, 'UserName', {}, 'Verified', {});
    end
    
    % Collect item details via command line
    fprintf('\n=== Add New Item ===\n');
    new_item.ItemName = input('Item name: ', 's');
    new_item.Price = input('Price ($): ');
    new_item.Condition = input('Condition (New/Used/Refurbished): ', 's');
    new_item.Location = input('Location: ', 's');
    new_item.UserName = input('Your username: ', 's');
    new_item.Verified = input('Verified seller? (Yes/No): ', 's');
    
    % Add to listings
    listings(end+1) = new_item;
    
    % Save to file
    save('listings.mat', 'listings');
    fprintf('\nItem "%s" added successfully!\n', new_item.ItemName);
end

function selltracsaction()
    if exist('listings.mat', 'file')
        load('listings.mat', 'listings');
    end

    % Simulate selecting an item to message the seller
    buyer_choice = input('Enter the number of the item you want to inquire about: ');
    if buyer_choice < 1 || buyer_choice > length(listings)
        disp('Invalid selection. Please restart the process.');
        return;
    end
    fprintf('You selected %s.\n', listings(buyer_choice).Item);
    
    
    % Simulate sending a message to the seller
    disp('Messaging the seller...');
    pause(1); % Simulate delay
    fprintf('Message to %s: "Hi, is this available?"\n', listings(buyer_choice).Seller);
    fprintf('Message from %s:"Yes, It is."', listings(buyer_choice).Seller);
    offerPrice = input('\nEnter you offer: ');
    fprintf('Message to %s: "I want to buy it for: %f"\n', listings(buyer_choice).Seller, offerPrice)
    
    
    if offerPrice < listings(buyer_choice).Price
        fprintf('Message from %s:"Sorry can not sell it for that much"', listings(buyer_choice).Seller);
        appro = 0;
    else
        fprintf('Message from %s:"Okay, Great. I will ship once the payment is approved."', listings(buyer_choice).Seller);
        appro = 1;
    end
    
    if appro == 1
        disp("Transection Screen.")
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
        
        % Combine first and last name
        payment_name = strcat(first_name, ' ', last_name);
        
        % Confirming the purchase
        disp('Processing transaction...');
        pause(2); % Simulate delay
        fprintf('Transaction Successful!\nThank you, %s, for purchasing %s for $%d.\n', payment_name, listings(buyer_choice).Item, listings(buyer_choice).Price);
        
        % Display order receipt
        disp('--- ORDER RECEIPT ---');
        fprintf('Buyer: %s\nItem: %s\nPrice: $%d\nSeller: %s\nLocation: %s\n', payment_name, listings(buyer_choice).Item, listings(buyer_choice).Price, listings(buyer_choice).Seller, listings(buyer_choice).Location);
        disp('----------------------');
        
        disp('Thank you for using our marketplace!');
    end
end

function regTransation()
    disp("Transection Screen.")
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
    fprintf('Order Name: %f %n \nMembership 1 Month: $5', first_name, last_name);
    disp('----------------------');
    
    disp('Thank you for using our marketplace!');   
end

function showlisting()
    % Check if the listings file exists
    if exist('listings.mat', 'file')
        % Load the struct 'listings'
        load('listings.mat', 'listings');
        
        % Check if listings exist
        if isempty(listings.listing)
            disp('No listings found.');
        else
            % Print header
            disp('=== CURRENT LUXURY LISTINGS ===');
            disp('----------------------------------------------------------------------------------------------------');
            fprintf('%-20s | %-10s | %-10s | %-15s | %-10s | %-10s | %-25s\n', ...
                   'Item Name', 'Price ($)', 'Condition', 'Location', 'User', 'Verified', 'Category');
            disp('----------------------------------------------------------------------------------------------------');
            
            % Loop through each listing and print details
            for i = 1:length(listings.ItemName)
                fprintf('%-20s | $%-9d | %-10s | %-15s | %-10s | %-10s | %-25s\n', ...
                        listings.ItemName{i}, ...
                        listings.Price{i}, ...
                        listings.Condition{i}, ...
                        listings.Location{i}, ...
                        listings.UserName{i}, ...
                        listings.Verified{i}, ...
                        listings.Category{i});
            end
            disp('----------------------------------------------------------------------------------------------------');
        end
    else
        disp('Error: listings.mat not found. No listings available.');
    end
end

disp('Welcome to Mache Deux')
fprintf('1) Sign Up \n2) Log In\n')
choice = input('Enter your choice: ');

%if choice == 1
%    approve = signUp();
%elseif choice == 2
%    approve = logIn();
%end

%if approve == true
    showlisting()
%end