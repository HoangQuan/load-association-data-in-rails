## **Load association data in rails**


Như các bạn đã biết, Rails cung cấp 4 cách khác nhau để load các dữ liệu có liên kết (dữ liệu liên kết qua các bảng).  

`Preload`, `Eagerload`, `Includes` và `Joins` là 4 cơ chế khác nhau để load các dữ liệu từ một bảng có quan hệ với một bảng khác (tôi tạm gọi là bảng nguồn và bảng mục tiêu).
Trong bài viết này tôi sẽ xem xét từng cơ chế một.

### **Preload**


`preload` sẽ load dữ liệu quan hệ thông qua các truy vấn tách biệt nhau. 

<br>

Chẳng hạn bạn muốn load ra toàn bộ bài viết của một user thông qua cơ chế `preload` thì thứ tự truy vấn vào database sẽ như sau:

<br>

 ```Ruby
User.preload(:posts).to_a

# =>
SELECT "users".* FROM "users"
SELECT "posts".* FROM "posts"  WHERE "posts"."user_id" IN (1)

```
<br>
Chính vì lý do trên nên trong rails người ta ít khi dùng `preload`, `includes` là cơ chế load dữ liệu quan hệ mặc định của Rails.

Cũng chính vì `preload` luôn luôn thực thi các truy vấn táck biệt nên bạn cũng không thể sử dụng thêm bất kỳ điều kiện `where` nào để truy vấn vào bảng mục tiêu sau đó.


Ví dụ: Tôi muốn tìm ra các bài viết có chứa nội dung "Ruby on rails" trong tiêu đề của user trên.
<br>
```Ruby
User.preload(:posts).where("posts.title='Ruby on rails'")
```

Một error sẽ được bắn ra:


```ruby
# =>
SQLite3::SQLException: no such column: posts.title:
SELECT "users".* FROM "users"  WHERE (posts.title='Ruby on rails')
```


Bạn chỉ có thể truy vấn vào các thuộc tính của bảng nguồn:

```ruby
User.preload(:posts).where("users.name='Neeraj'")

# =>
SELECT "users".* FROM "users"  WHERE (users.name='Neeraj')
SELECT "posts".* FROM "posts"  WHERE "posts"."user_id" IN (3)

```

### **Includes**

`Includes` load dữ liệu thông qua các truy vấn riêng biệt giống như `preload`

Tuy nhiên, `Includes` thông mình hơn `preload`. Theo ví dụ ở trên ta công thể thực hiện thêm bất cứ truy vấn `where` nào cho thuộc tính ở bảng mục tiêu nữa `User.preload(:posts).where("posts.title='Ruby on rails'")`, Hãy thử với `includes` nhé:
<br>


```
User.includes(:posts).where('posts.desc = "ruby is awesome"').to_a

# =>
SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "posts"."id" AS t1_r0,
       "posts"."title" AS t1_r1,
       "posts"."user_id" AS t1_r2, "posts"."desc" AS t1_r3
FROM "users" LEFT OUTER JOIN "posts" ON "posts"."user_id" = "users"."id"
WHERE (posts.desc = "ruby is awesome")

```
<br>

Như bạn đã thấy, `Includes` đã chuyển từ việc sử dụng hai query thành việc sử dụng một câu truy vấn đơn sử dụng `LEFL OUTER JOIN` để lấy dữ liệu. Và nó có thể cung cấp các điều kiện đi kèm.

Như vậy, `Includes` thay đổi từ hai truy vấn thành một truy vấn duy nhất trong một số trường hợp. Mặc định các trường hợp thông thường thì sẽ tạo hai truy vấn, Trong trường hợp bạn mong muốn thực hiện chỉ một truy vấn, Hãy nói cho Rails biết thông qua `references` :

```ruby

User.includes(:posts).references(:posts).to_a

# =>
SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "posts"."id" AS t1_r0,
       "posts"."title" AS t1_r1,
       "posts"."user_id" AS t1_r2, "posts"."desc" AS t1_r3
FROM "users" LEFT OUTER JOIN "posts" ON "posts"."user_id" = "users"."id"

```

Ở ví dụ trên, Một truy vấn đã được thực hiện.
<br>

### **Eager Load**

`Eager load` sẽ tải toàn bộ dữ liệu quan hệ trong một truy vấn duy nhất sử dụng `LEFT OUTER JOIN`

<br>
```
User.eager_load(:posts).to_a

# =>
SELECT "users"."id" AS t0_r0, "users"."name" AS t0_r1, "posts"."id" AS t1_r0,
       "posts"."title" AS t1_r1, "posts"."user_id" AS t1_r2, "posts"."desc" AS t1_r3
FROM "users" LEFT OUTER JOIN "posts" ON "posts"."user_id" = "users"."id"

```
<br>

Đây chính xác là những gì `includes` làm khi nó thực hiện một truy vấn đơn duy nhất kèm theo mệnh đề `where` hoặc `order` trên bảng mục tiêu (bảng `posts`).

<br>

### **Joins**

Joins sẽ tải toàn bộ dữ liệu của bảng quan hệ sử dụng `INNER JOIN`.


```
User.joins(:posts)

# =>
SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id"
```
<br>

Câu truy vấn trên có thể trả về dữ liệu với một số records bị trùng lặp. Để thấy được điều đó tôi sẽ tạo một số dữ liệu mẫu cho các bảng:

<br>
```
def self.setup
  User.delete_all
  Post.delete_all

  u = User.create name: Quan
  u.posts.create! title: 'ruby', desc: 'ruby is awesome'
  u.posts.create! title: 'rails', desc: 'rails is awesome'
  u.posts.create! title: 'JavaScript', desc: 'JavaScript is awesome'

  u = User.create name: Hoang
  u.posts.create! title: 'JavaScript', desc: 'Javascript is awesome'

  u = User.create name: HoangQuan
end

```

Với dữ liệu trên kết quả sẽ là:

```
#<User id: 9, name: "Quan">
#<User id: 9, name: "Quan">
#<User id: 9, name: "Quan">
#<User id: 10, name: "Hoang">

```
Để tránh việc duplication dữ liệu hãy sử dụng `distinct`

```
User.joins(:posts).select('distinct users.*').to_a
```


Nếu bạn muốn sử dụng một số thuộc tính của bảng `posts` hãy select chúng"

```
records = User.joins(:posts).select('distinct users.*, posts.title as posts_title').to_a
records.each do |user|
  puts user.name
  puts user.posts_title
end

```
<br>

Chú ý rằng thay vì sử dụng select trong joins bạn sử dụng `user.posts` đồng nghĩa với việc bạn đã thực hiện một truy vấn khác vào databases. Vấn đề này khá quan trọng đối với hiệu xuất của dự án - `Vấn đề N + 1 queries`.

Tôi sẽ lấy ví dụ cụ thể để giải thích vấn đề này:


Tôi sẽ tạo ra một số bảng và biểu diễn mối quan hệ giữa chúng như sau:

```
# app/models/user.rb
class User < ActiveRecord::Base
  has_many :posts
  has_many :comments
end


# app/models/post.rb
class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments
end


# app/models/comment.rb
class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
end

```


Thông thường chúng ta sẽ làm như sau để lấy ra bài viết của một danh sách các tác giả:

```ruby
# users_controller.rb
@users = User.limit(10)

# Views

@users.each  do |user|
	user.name
	user.posts.count ...
end
```

Điều này gây ra vấn đề N +1 queries (1 truy vấn cho find 10 users +  10 truy vấn để load số lượng bài posts của user).

Điều này sẽ làm chậm hệ thống của bạn như thế nào?

Hãy cùng tôi kiểm tra nó:

Tạo một số dữ liệu mẫu:

```
# db/seeds.rb

require 'faker'
users = Array.new(80) do
  User.create(name: Faker::Name.name)
end

posts = Array.new(80) do
  Post.create(user: users.sample, title: Faker::Lorem.sentence, body: Faker::Lorem.paragraph)
end

128.times do
  users.each do |user|
    posts.each do |post|
      Comment.create(user: user, post: post, message: Faker::Lorem.sentence)
    end
  end
end

```


trên Views thông thường chúng ta sẽ làm như sau:

```
<h1>All Posts</h1>

<% @posts.each do |post| %>
	<ul>
		<li><%= post.title %></li>
		<li><%= post.user.name %></li>
		<ul>
			<% post.comments.each do |comment| %>
				<li><%= comment.message %></li>
			<%end%>
		</ul>
	</ul>
<%end%>

```

Kết quả là tải trang này với hàng trăm queries và mất khoảng `2000ms`.

Như tôi đã đề cập ở trên, để tránh N + 1 queries chúng ta hãy dùng thử `Includes`:

```
@posts = Post.includes(:user, comments: :user)

```

Bây giờ số queries đã giảm xuống còn 5 queries và thời gian tải trang là 500ms. 
nhanh hơn gấp 4 lần rồi đúng không?

Chỉ với một thao tác khá đơn giản nhưng hiệu quả tương đối lớn.


Cảm ơn đã đọc bài viết.

Source code: https://github.com/HoangQuan/load-association-data-in-rails.git

