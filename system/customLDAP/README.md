# update user

Avatar

<!-- data.name -->
<!-- data.customFields.Tel -->

<!-- data.email -->
<!-- data.customFields.Mail -->

<!-- data.customFields.City -->
<!-- data.customFields.Title -->
<!-- data.customFields.Department -->

data.customFields	cart to US
<!-- data.active 		status(?) -->

data.joinDefaultChannels

## Замечания

Аватар может подтягиваться не сразу, если фото не добавлена

```sh
git clone https://github.com/Matthias-Wandel/jhead /tmp/jhead
make -C /tmp/jhead
sudo make -C /tmp/jhead install
```

```sh
        echo '{"userId": "'$u_id'",
        "data": {
            "name": "'$displayName'",
            "customFields": {
                "Mail": "'$mail'",
                "Tel": "'$telephoneNumber'",
                "City": "'$city'",
                "Title": "'$title'",
                "Department": "'$department'"
        }}}' >$json
```

Вынести операции в отлельные файлы
