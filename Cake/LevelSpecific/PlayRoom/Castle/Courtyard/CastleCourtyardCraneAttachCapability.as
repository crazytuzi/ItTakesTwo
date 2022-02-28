import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneMagnet;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleCourtyardCraneActor;

class UCastleCourtyardCraneAttachCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"SwingHorizontal");

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ACourtyardCraneMagnet Magnet;
	ACourtyardCraneWreckingBall WreckingBall;
	ACastleCourtyardCraneActor CraneActor;

	bool bAttached = false;
	const float AttachTime = 0.4f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Magnet = Cast<ACourtyardCraneMagnet>(Owner);
		Magnet.SphereTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		WreckingBall = Cast<ACourtyardCraneWreckingBall>(OtherActor);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (bAttached)
			return EHazeNetworkActivation::DontActivate;
			
		if (WreckingBall == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FMath::Clamp(ActiveDuration / AttachTime, 0.f, 1.f) < 1.f)		
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"WreckingBall", WreckingBall);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Magnet.SetCapabilityActionState(n"Attached", EHazeActionState::Inactive);
		
		WreckingBall = Cast<ACourtyardCraneWreckingBall>(ActivationParams.GetObject(n"WreckingBall"));
		CraneActor = Cast<ACastleCourtyardCraneActor>(GetAttributeObject(n"CraneActor"));
		Magnet.OnOverlapWreckingBall.Broadcast();

		//FVector CraneToWreckingBall = (WreckingBall.ActorLocation - CraneActor.ActorLocation).ConstrainTo;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bAttached = true;

		Magnet.Root.AttachToComponent(WreckingBall.AttachPointMagnet, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);		
		Magnet.OnAttachWreckingBall.Broadcast(WreckingBall);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float AttachPercentage = FMath::Clamp(ActiveDuration / AttachTime, 0.f, 1.f);

		FVector ToTarget = WreckingBall.AttachPointMagnet.WorldLocation - Owner.ActorLocation;
		Magnet.LinearVelocity -= Magnet.LinearVelocity * 2.f * DeltaTime;
		Magnet.LinearVelocity += ToTarget.GetSafeNormal() * 400.f * DeltaTime;

		FVector DeltaMove = FMath::Lerp(Magnet.LinearVelocity * DeltaTime, ToTarget, AttachPercentage);
		Owner.ActorLocation = Owner.ActorLocation + DeltaMove;

		FVector ToConstraint = CraneActor.ConstraintPoint.WorldLocation - Owner.ActorLocation;
		FRotator TargetRotation = FRotator::MakeFromZX(ToConstraint, -CraneActor.ConstraintPoint.ForwardVector);
		Owner.ActorRotation = FMath::RInterpTo(Owner.ActorRotation, TargetRotation, DeltaTime, 7.f);
		WreckingBall.ActorRotation = FMath::RInterpTo(WreckingBall.ActorRotation, TargetRotation, DeltaTime, 7.f);
	}
}