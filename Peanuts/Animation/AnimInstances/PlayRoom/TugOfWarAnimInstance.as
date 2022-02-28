import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureTugOfWar;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarPlayerComponent;

class UTugOfWarAnimInstance : UHazeFeatureSubAnimInstance
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ULocomotionFeatureTugOfWar LocomotionFeature;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float ButtonMashRate;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsButtonMashing;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsAlone;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bTakeAStep;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlayStruggle;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bGameOver;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlayExit;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bStepForwards;

	// Value determining stateshift -10 / 10 will increase/decrease state
	UPROPERTY(NotEditable, BlueprintReadOnly)
	float StepProgress;
	
	//Holds individual / shared values
	UTugOfWarPlayerComponent TugOfWarPlayerComp;

	//State of game between -TotalSteps : TotalSteps
	int CurrentStep;
	int TotalSteps;
	bool bIsPlayerOnLeft;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		LocomotionFeature = Cast<ULocomotionFeatureTugOfWar>(GetFeatureAsClass(ULocomotionFeatureTugOfWar::StaticClass()));
		TugOfWarPlayerComp = UTugOfWarPlayerComponent::GetOrCreate(OwningActor);
		bIsPlayerOnLeft = TugOfWarPlayerComp.bIsPlayer1;
		CurrentStep = TugOfWarPlayerComp.CurrentStep;
		TotalSteps = TugOfWarPlayerComp.TotalSteps;
		bPlayStruggle = false;
		bPlayExit = false;
		
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (TugOfWarPlayerComp == nullptr)
			return;

		bIsButtonMashing = TugOfWarPlayerComp.bIsButtonMashing;
		StepProgress = TugOfWarPlayerComp.StepProgress;
		bIsAlone = TugOfWarPlayerComp.bIsInteractingAlone;

		if (bIsButtonMashing && !bIsAlone)
			bPlayStruggle = true;
		
		bPlayExit = (GetLocomotionAnimationTag() != n"TugOfWar");

		bTakeAStep = (CurrentStep != TugOfWarPlayerComp.CurrentStep);
		
		if (bTakeAStep)
		{
			const bool bStepLeft = (CurrentStep < TugOfWarPlayerComp.CurrentStep);
			if (bIsPlayerOnLeft)
				bStepForwards = !bStepLeft;
			else
				bStepForwards = bStepLeft;

			CurrentStep = TugOfWarPlayerComp.CurrentStep;
			bGameOver = (FMath::Abs(CurrentStep) > TotalSteps);
		}
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom()
	{
		if (bGameOver)
			return true;
			
		if (TopLevelGraphRelevantAnimTimeRemaining == 0.f && TopLevelGraphRelevantStateName == n"Exit")
			return true;

		return (OwningActor.GetActorVelocity().Size() > 300.f);
	}

}