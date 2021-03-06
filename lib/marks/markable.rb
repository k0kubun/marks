module Marks
  module Markable
    extend ActiveSupport::Concern

    module ClassMethods
      def markable_with(*types)
        has_many :incoming_marks, as: :markable, dependent: :destroy, class_name: 'Marks::Mark'

        types.each do |type|
          # just for preload_marker's result cache, which is used by marked_by?
          has_one :"#{type}_marked_flag"
        end

        class_eval do
          define_method :'markers' do |class_name, mark|
            classified_mark = mark.to_s.classify
            raise ArgumentError unless types.map { |t| t.to_s.classify }.include?(classified_mark)
            klass = class_name.to_s.classify.constantize
            klass.joins(:outgoing_marks).where('marks_marks.mark_type = ? AND markable_type = ? AND markable_id = ?', mark.to_s.classify, self.class.base_class.to_s, self)
          end

          define_method :'marked_by?' do |marker, mark|
            classified_mark = mark.to_s.classify
            raise ArgumentError unless types.map { |t| t.to_s.classify }.include?(classified_mark)
            return false unless marker

            # if preload_marker is executed, use its result
            if self.association(:"#{mark}_marked_flag").loaded?
              return self.association(:"#{mark}_marked_flag").target
            end

            klass = marker.class.table_name.classify.constantize
            klass.joins(:outgoing_marks).where('marks_marks.mark_type = ? AND markable_type = ? AND markable_id = ?', mark.to_s.classify, self.class.base_class.to_s, self).any?
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Marks::Markable
