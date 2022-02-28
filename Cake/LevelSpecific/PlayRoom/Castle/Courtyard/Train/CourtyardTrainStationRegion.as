import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainTrack;

class UCourtyardTrainStationRegion : UHazeSplineRegionComponent
{
	ACourtyardTrainTrack TrainTrack;

	UFUNCTION(BlueprintOverride)
	void OnRegionInitialized()
	{
	}

	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Teal;
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		TrainTrack = Cast<ACourtyardTrainTrack>(Owner);
		TrainTrack.StationPositionStart = GetStartPosition();
		TrainTrack.StationPositionEnd = GetEndPosition();
	}
}