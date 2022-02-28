import Cake.LevelSpecific.Music.Smooch.Smooch;
import Cake.LevelSpecific.Music.Smooch.SmoochNames;

class USmoochRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(Smooch::Smooch);
	default CapabilityDebugCategory = n"Smooch";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	USmoochUserComponent SmoochComp;

	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SmoochComp = USmoochUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Player.IsCody())
	        return EHazeNetworkActivation::DontActivate;

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
		Player.AttachToActor(SmoochComp.RotateRoot, NAME_None, EAttachmentRule::KeepWorld);
		Player.OtherPlayer.AttachToActor(SmoochComp.RotateRoot, NAME_None, EAttachmentRule::KeepWorld);

		StartRotation = SmoochComp.RotateRoot.ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DetachRootComponentFromParent(true);
		Player.OtherPlayer.DetachRootComponentFromParent(true);
	}

	float Time = 0.f;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Time += 0.07 * DeltaTime;
		float Angle = FMath::Sin(Time) * -4.f;

		// Limit the amount of rotation the further into the kiss we go, to make the cutscene blend work
		Angle *= (1.f - GetSmoochMinimumProgress());

		FRotator AnimRotation = StartRotation;
		AnimRotation.Yaw += Angle;
		SmoochComp.RotateRoot.ActorRotation = AnimRotation;
	}
}
