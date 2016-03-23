class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post

  scope :recent, -> (count = 2) {
    subselect <<-SQL
	    SELECT COUNT(*)
	    FROM comments AS rcomments
	    WHERE rcomments.post_id = comments.post_id AND rcomments.id > comments.id
    SQL
    where(":count > (#{subselect})").order(id: "DESC")
  }

  # While this optimization works great for tiny data sets the SQL query it generates is quadratic. 
  # When the posts start to have thousands of comments the runtime jumps to well over 2000ms. 
  # Running an explain analyze provides some insights that a simple index addition won't fix it. 
  # Fortunately PostgreSQL (and many other databases) support a much faster alternative method using "window functions":

  # scope :recent, -> (count = 2) { 
  #   rankings = "SELECT id, RANK() OVER(PARTITION BY post_id ORDER BY id DESC) rank FROM comments"

  #   joins("INNER JOIN (#{rankings}) rankings ON rankings.id = comments.id")
  #     .where("rankings.rank < :count", count: count.next)
  #     .order(id: "DESC")
  # }
end
