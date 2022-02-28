import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarManagerComponent;

class UTugOfWarPlayerComponent : UActorComponent
{
	int CurrentStep = 0;
	int TotalSteps = 0;
	float StepProgress = 0.f;
	float ButtonMashRate = 0.f;
	bool bIsInteractingAlone = true;
	bool bIsButtonMashing = false;
	bool bIsPlayer1 = false;
	bool bIsExitingInteraction = false;

	UTugOfWarManagerComponent ManagerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(ManagerComp != nullptr)
		{
			CurrentStep = ManagerComp.CurrentStep;
			StepProgress = ManagerComp.StepProgress;

			bIsInteractingAlone = !ManagerComp.bInteractionStarted;

			if(!FMath::IsNearlyZero(ManagerComp.MashDelta, 0.00001f))
				bIsButtonMashing = true;
			else
				bIsButtonMashing = false;
		}
	}
}