import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneDeathCapability : UHazeCapability
{
	FMurderMicrophoneBodyTravel BodyTravel;

	FVector StartLocation;

	AMurderMicrophone Snake;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UMurderMicrophoneMovementComponent MoveComp;

	UNiagaraComponent FuseFX;

	private bool bKillComplete = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		MoveComp = UMurderMicrophoneMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Snake.CurrentState != EMurderMicrophoneHeadState::Killed)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bKillComplete = false;
		
		if(Snake.ElectricityBallStart != nullptr)
			Snake.ElectricityBallAkComp.HazePostEvent(Snake.ElectricityBallStart);
		
		BodyTravel.StartTravel(Snake, EMurderMicrophoneBodyTravelType::CoreToHead);
		const FVector NewTargetLocation = Snake.HeadOffset.WorldLocation + FVector::UpVector * 600.0f;
		MoveComp.SetTargetLocation(NewTargetLocation);
		Snake.ApplySettings(Snake.DeathSettings, this, EHazeSettingsPriority::Override);
		MoveComp.ResetMovementVelocity();
		FuseFX = Niagara::SpawnSystemAtLocation(Snake.CordFuseFX, Snake.CordExitWorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float TravelSpeed = (TargetingComp.ChaseRange / FMath::Max(Snake.CordLengthCurrent, 1000.0f));
		FVector Location = FVector::ZeroVector;
		bool bDone = false;
		BodyTravel.Travel(Location, bDone, DeltaTime, TravelSpeed);
		FuseFX.SetWorldLocation(Location);
		Snake.ElectricityBallAkComp.SetWorldLocation(Location);
		const float FlippedAlpha = (BodyTravel.Alpha - 1.0f) * -1.0f;
		Snake.ElectricityBallAkComp.SetRTPCValue("Rtpc_World_Shared_Interactables_ElectricBall_Progress", FlippedAlpha);
		
		int NumPoint = Snake.GetNumSplinePoints();
		int SplinePathPoints = Snake.SplinePath.Num();
		float SplinePathFraction = float(NumPoint) / float(SplinePathPoints);
		//PrintToScreen("SplinePathFraction " + SplinePathFraction);
		//const float FillDistance = Snake.GetFillDistance(BodyTravel.Alpha) + 1.0f;
		//PrintToScreen("ReversedAlpha " + ReversedAlpha);
		//PrintToScreen("Alpha " + BodyTravel.Alpha);
		//PrintToScreen("FillDistance " + FillDistance);
		//Snake.BodyComponent.SetScalarParameterValueOnMaterialIndex(0, n"FillDistance", FillDistance);
		//System::DrawDebugSphere(Location, 100, 12, FLinearColor::Red, 0, 10);
		Snake.BodyComponent.SetScalarParameterValueOnMaterialIndex(0, n"BlendPct", BodyTravel.Alpha * SplinePathFraction);
		if(bDone)
			bKillComplete = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bKillComplete)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Snake.ClearSettingsByInstigator(this);
		Niagara::SpawnSystemAtLocation(Snake.HeadExplosionFX, Snake.SnakeHeadCordLocation);
		Snake.Finalize_MurderMicrophoneDestroy();
		FuseFX.Deactivate();

		if(Snake.ElectricityBallStart != nullptr)
			Snake.ElectricityBallAkComp.HazePostEvent(Snake.ElectricityBallEnd);
	}

}
