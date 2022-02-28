import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrain;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainCarriageRidable;
class UCourtyardTrainUserComponent : UActorComponent
{
	ACourtyardTrain Train;
	ACourtyardTrainCarriageRidable Carriage;
	
	UInteractionComponent InteractionComp;
	ECourtyardTrainState State;

	bool bFirstPersonCameraActive = false;

	bool bOnTrain = false;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ThirdPersonCameraSettings;
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset FirstPersonCameraSettings;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;
}

enum ECourtyardTrainState
{
	Inactive,
	Train,
	Carriage
}