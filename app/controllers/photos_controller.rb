class PhotosController < ApplicationController
  def destroy
    return head :not_found unless Photo.exists?(params[:id])

    Photo.destroy(params[:id])
    head :ok
  end
end
