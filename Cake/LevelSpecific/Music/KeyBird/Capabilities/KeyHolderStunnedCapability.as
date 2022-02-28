import Cake.SteeringBehaviors.SteeringBehaviorComponent;
import Cake.LevelSpecific.Music.KeyBird.KeyBird;

class UKeyHolderStunnedCapability : UHazeCapability
{
	USteeringBehaviorComponent Steering;
	AKeyBird KeyBird;

	FHazeAcceleratedFloat TargetYawOffset;

	float DefaultDrag;
	float TargetYaw;
	float Elapsed = 0.0f;
	float TargetTime = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Steering = USteeringBehaviorComponent::Get(Owner);
		KeyBird = Cast<AKeyBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(n"KeyHolderStunned"))
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"SteeringEvade", this);
		Owner.BlockCapabilities(n"SteeringCharacterAvoidance", this);
		Owner.BlockCapabilities(n"SteeringConstrainWithinRadius", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"SteeringEvade", this);
		Owner.UnblockCapabilities(n"SteeringCharacterAvoidance", this);
		Owner.UnblockCapabilities(n"SteeringConstrainWithinRadius", this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Elapsed > TargetTime)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetYawOffset.AccelerateTo(TargetYaw, TargetTime - 1.0f, DeltaTime);
		KeyBird.MeshBody.SetRelativeRotation(FRotator(0.0f, TargetYawOffset.Value, 0.0f));
		Elapsed += DeltaTime;

		if(IsActioning(n"KeyHolderStunned"))
		{
			TriggerHit();
		}
	}

	void TriggerHit()
	{
		TargetYaw += 360.0f * 10.0f;
		Elapsed = 0.0f;
		TargetTime = 14.0f;
	}
}
