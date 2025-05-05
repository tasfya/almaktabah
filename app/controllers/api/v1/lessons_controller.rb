module Api
    module V1
      class LessonsController < ApiController
        def index
            page = params[:page]&.to_i || 1
            per_page = params[:per_page]&.to_i || 10
            
            lessons = Lesson.all
            
            if params[:title].present?
                lessons = lessons.where("LOWER(title) LIKE LOWER(?)", "%#{params[:title]}%")
            end

            if params[:category].present?
                lessons = lessons.where("LOWER(category) LIKE LOWER(?)", "%#{params[:category]}%")
            end
            
            total_items = lessons.count
            total_pages = (total_items.to_f / per_page).ceil
            
            offset = (page - 1) * per_page
            paginated_lessons = lessons.offset(offset).limit(per_page)
            
            render json: {
                lessons: ActiveModel::Serializer::CollectionSerializer.new(
                    paginated_lessons,
                    serializer: LessonSerializer
                ),
                meta: {
                    current_page: page,
                    per_page: per_page,
                    total_items: total_items,
                    total_pages: total_pages,
                    categories: categories
                }
            }
        end        
  
        def show
          lesson = Lesson.find(params[:id])
          render json: lesson
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Lesson not found" }, status: :not_found
        end


        def categories
          Lesson.select(:category).distinct.pluck(:category)
        end

        def recent
            lessons = Lesson.order(published_date: :desc).limit(10)
          render json: lessons
        end
      end
    end
  end
