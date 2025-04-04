listings = struct(...
    'ItemName', {'Hermes Handbag', 'Vertu Ironflip'}, ...
    'Price', {4200, 3000}, ...
    'Condition', {'Used', 'New'}, ...
    'Location', {'Toronto', 'North York'}, ...
    'UserName', {'Alice', 'Bob'}, ...
    'Verified', {'Yes', 'No'}, ...
    'Category', {'Fashion & Accessories', 'Electronics & Gadgets'} ...
);

userInfo = struct(...
    'Username', {'bob', 'mike'}, ...
    'Password', {'123456', '222222'}, ...
    'Verified', {'No', 'Yes'} ...
);
save('listings.mat', 'listings', '-v7.3');  % Use -v7.3 format for reliability