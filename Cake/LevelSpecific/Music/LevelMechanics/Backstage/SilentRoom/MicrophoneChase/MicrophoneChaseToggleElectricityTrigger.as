import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneChaseElectricity;
class AMicrophoneChaseToggleElectricityTrigger : APlayerTrigger
{
	UPROPERTY()
	bool bSetElectricityEnabled = false;
	
	bool bHasBeenTriggered = false;	

	AMicrophoneChaseElectricity Electricity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnPlayerEnter.AddUFunction(this, n"PlayerEnterTrigger");
		TArray<AMicrophoneChaseElectricity> TempArray;
		GetAllActorsOfClass(TempArray);
		Electricity = TempArray[0];

		Super::BeginPlay();
	}	

	UFUNCTION()
	void PlayerEnterTrigger(AHazePlayerCharacter Player) 
	{
		if (bHasBeenTriggered)
			return;

		bHasBeenTriggered = true;
		Electricity.SetElectricityEnabled(bSetElectricityEnabled);
	}
}