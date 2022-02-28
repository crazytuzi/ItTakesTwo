import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannon;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonShooterComponent;
import Vino.Camera.Components.CameraUserComponent;

class UCastleCannonAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"Cannon";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCastleCannonShooterComponent Shooter;
	UCameraUserComponent CameraUser;

	ACastleCannon Cannon;
	USceneComponent CameraPivot;
	UHazeCameraComponent Camera;

	FVector MuzzleDirection;

	FVector CameraForwardVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Shooter = UCastleCannonShooterComponent::GetOrCreate(Owner);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Shooter.ActiveCannon == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Shooter.ActiveCannon != Cannon)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cannon = Shooter.ActiveCannon;
		Camera = Cannon.Camera;
		CameraPivot = Cannon.CameraPivot;

		CameraUser.SetDesiredRotation(CameraPivot.WorldRotation);

		Player.ApplyCameraSettings(Cannon.SpringArmSettings, FHazeCameraBlendSettings(1.f), this );


		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.f;
		Player.ActivateCamera(Camera, BlendSettings, this);

		CameraUser.SetAiming(this);

		MuzzleDirection = Cannon.Muzzle.ForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DeactivateCameraByInstigator(this, 0.8f);
		Player.ClearSettingsByInstigator(this);

		Camera = nullptr;
		Cannon = nullptr;
		CameraPivot = nullptr;

		CameraUser.ClearAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CameraPivot.SetWorldRotation(CameraUser.DesiredRotation);

		FVector TargetMuzzleDirection = CameraUser.DesiredRotation.ForwardVector;

		FQuat CurrentQuat = Math::MakeQuatFromX(MuzzleDirection);
		FQuat TargetQuat = Math::MakeQuatFromX(TargetMuzzleDirection);

		FQuat LerpedQuat = FQuat::Slerp(CurrentQuat, TargetQuat, 10.f * DeltaTime);
		MuzzleDirection = LerpedQuat.ForwardVector;

		Cannon.YawPivot.SetWorldRotation(Math::MakeRotFromX(MuzzleDirection));

		Cannon.SetActorHiddenInGame(false);
	}
}
