import Vino.Pickups.PlayerPickupComponent;
import Vino.Time.ActorTimeDilationStatics;
import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeComponent;

class UTrapezeMarbleCatchTimeDilationCapabilityBase : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::MarbleCatchTimeDilation);

	default TickGroup = ECapabilityTickGroups::GamePlay;

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PickupComponent;
	UTrapezeComponent TrapezeInteractionComponent;

	ATrapezeMarbleActor MarbleActor;

	float LerpStart, LerpTarget;
	float LerpAlpha;

	const float LerpTime = 0.05f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);
		TrapezeInteractionComponent = UTrapezeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LerpAlpha += DeltaTime / LerpTime;
		if(LerpAlpha < 1.0f)
			Time::SetWorldTimeDilation(FMath::Lerp(LerpStart, LerpTarget, LerpAlpha));
	}
}