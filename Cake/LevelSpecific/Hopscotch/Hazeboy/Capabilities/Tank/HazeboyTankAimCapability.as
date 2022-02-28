import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyPlayerComponent;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

class UHazeboyTankAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazeboyTank Tank;
	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUser;

	float ControlSideRotation = 0.f;
	float ControlSyncTime = 0.f;
	float SyncAimSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tank = Cast<AHazeboyTank>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ControlSideRotation = Tank.SpringArm.WorldRotation.Yaw;
		Player = Tank.OwningPlayer;
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurrentRotation = Tank.SpringArm.WorldRotation.Yaw;
		float DeltaAngle = 0.f;

		if (HasControl())
		{
			float TurnRate = CalculateTurnRate();

			FVector Input = GetAttributeVector(AttributeVectorNames::CameraDirection);
			DeltaAngle = Input.X * TurnRate * DeltaTime;

			// Sync that bad boy!
			float Time = Time::GameTimeSeconds;
			if (Time > ControlSyncTime)
			{
				NetSendControlSideRotation(CurrentRotation);
				ControlSyncTime = Time + (1.f / Hazeboy::AimSyncFrequency);
			}
		}
		else
		{
			float ControlSideDelta = FMath::FindDeltaAngleDegrees(CurrentRotation, ControlSideRotation);

			// We want to rotate with a constant speed, unless the delta towards the control side is smaller
			DeltaAngle = FMath::Min(FMath::Abs(ControlSideDelta), SyncAimSpeed * DeltaTime);
			DeltaAngle = DeltaAngle * FMath::Sign(ControlSideDelta);
		}

		CurrentRotation += DeltaAngle;
		Tank.SpringArm.WorldRotation = FRotator(0.f, CurrentRotation, 0.f);

		// Event for audio!
		Tank.BP_OnAim(FMath::Clamp((DeltaAngle / DeltaTime) / Hazeboy::AimSpeed, -1.f, 1.f));

		// Calculate relative yaw for the turret..
		FVector TurretForward = Tank.SpringArm.ForwardVector;
		TurretForward = Tank.Root.WorldTransform.InverseTransformVector(TurretForward);

		float TurretAngle = FMath::RadiansToDegrees(FMath::Atan2(TurretForward.Y, TurretForward.X));
		Tank.TurretRoot.RelativeRotation = FRotator(0.f, TurretAngle, 0.f);
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSendControlSideRotation(float Rotation)
	{
		float CurrentRotation = Tank.SpringArm.WorldRotation.Yaw;

		// Calculate how fast we need to rotate to get to this point before the next rotation comes in
		float AbsDelta = FMath::Abs(FMath::FindDeltaAngleDegrees(CurrentRotation, ControlSideRotation));
		SyncAimSpeed = FMath::Min(AbsDelta / (1.f / Hazeboy::AimSyncFrequency), Hazeboy::AimSpeed);

		ControlSideRotation = Rotation;
	}

	float CalculateTurnRate()
	{
		float Sensitivity = 1.f;
		if (Player.IsUsingGamepad())
			Sensitivity = Player.GetSensitivity(EHazeSensitivityType::Yaw);
		else
			Sensitivity = Player.GetSensitivity(EHazeSensitivityType::MouseYaw);

		if (Player.IsCameraYawInverted())
			Sensitivity= -Sensitivity;

		return Sensitivity * CameraUser.GetCameraTargetTurnRate().Yaw * 0.4f;
	}
}