import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingPlayerComp;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;

class UAxeThrowingCameraAimCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingCameraDefaultCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	// After camera updates
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	AHazePlayerCharacter Player;

	UAxeThrowingPlayerComp PlayerComp;

	UCameraUserComponent UserComp;

	UHazeUserWidget WidgetInUse;

	FHazeTraceParams TraceParams;

	FVector CharacterForwardVector;

	float RightCamInput;

	float AimMaxAngle = 35.f;

	float TotalAmount = 44.f;
	float MaxValueFromTest = 80.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UAxeThrowingPlayerComp::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)	
	{
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
		TraceParams.InitWithObjectTypes(ObjectTypes);

		TraceParams.InitWithCollisionProfile(n"BlockAll");

		TraceParams.SetToLineTrace();

		CharacterForwardVector = Player.ActorForwardVector;

		// UserComp.SetAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// WidgetInUse = Cast<UHazeUserWidget>(Player.AddWidget(PlayerComp.AimWidget));
		// Player.RemoveWidget(WidgetInUse);
		// UserComp.ClearAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PlayerAim();
		PlayerRotationControl();
	}

	UFUNCTION()
	void PlayerAim()
	{
		TraceParams.From = Player.ViewLocation;
		TraceParams.To = Player.ViewLocation + Player.ViewRotation.ForwardVector * 10000.f;

		FHazeHitResult Hit;
		FVector HitLoc = Hit.TraceEnd;

		if (TraceParams.Trace(Hit))
		{
			HitLoc = Hit.GetImpactPoint();
			PlayerComp.CurrentTarget = Cast<AAxeThrowingTarget>(Hit.Actor);
		}

		PlayerComp.EndLocation = HitLoc;
	}

	UFUNCTION()
	void TempSetAxeLocation(FVector Loc, FVector LookDirection)
	{
		if (PlayerComp.ChosenAxe == nullptr)
			return;

		bool IsDisabled = PlayerComp.ChosenAxe.IsActorDisabled(); 

		PlayerComp.ChosenAxe.SetActorLocation(Loc);
		PlayerComp.ChosenAxe.SetActorRotation(LookDirection.Rotation());
	}

	UFUNCTION()
	void PlayerRotationControl()
	{
		RightCamInput = GetAttributeValue(AttributeNames::CameraYaw);

		FRotator PlayerDesiredRot = FRotator(0.f, UserComp.DesiredRotation.Yaw, 0.f);
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);

		MoveComp.SetTargetFacingRotation(PlayerDesiredRot, 150.f); 

		float RightAngle = Player.ActorRightVector.DotProduct(CharacterForwardVector);
		
		float RotValue = FMath::Abs(UserComp.DesiredRotation.Yaw);
		RotValue = FMath::RoundToInt(RotValue);

		float ZeroToMax = RotValue - TotalAmount;
		
		PlayerComp.BSPlayerTurn = ZeroToMax / MaxValueFromTest;
	}
}