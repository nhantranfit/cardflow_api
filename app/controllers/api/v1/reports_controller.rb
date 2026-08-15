module Api
  module V1
    class ReportsController < ApplicationController
      def index
        authorize :report, :index?

        reports = if current_user.admin?
                    AdminOperationsReportQuery.new(params: report_params).call
        else
                    ClientOperationsReportQuery.new(
                      client: current_user,
                      params: report_params
                    ).call
        end

        render json: reports, each_serializer: OperationReportSerializer, root: "reports"
      end

      private

      def report_params
        if current_user.admin?
          params.permit(:status, :brand_id, :client_id)
        else
          params.permit(:status)
        end
      end
    end
  end
end
