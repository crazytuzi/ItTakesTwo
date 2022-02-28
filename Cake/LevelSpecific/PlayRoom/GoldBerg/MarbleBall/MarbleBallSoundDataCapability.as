import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;

class UMarbleBallSoundCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;
	default TickGroupOrder = 100;

	FVector StoredVelocity;

	AMarbleBall Marble;
	default CapabilityTags.Add(n"Audio");

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Marble = Cast<AMarbleBall>(Owner);
		Marble.Mesh.OnComponentHit.AddUFunction(this, n"OnHit");
	}

	UFUNCTION()
	void OnHit(UPrimitiveComponent hitComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, FVector NormalImpulse, FHitResult& Hit)
	{
		float DotToImpact = Hit.ImpactNormal.GetSafeNormal().DotProduct(StoredVelocity.GetSafeNormal());

		System::DrawDebugLine(Hit.Location, Hit.Location + Hit.Normal * 100);

		if (DotToImpact < -0.6f && Marble.bCanPlayHitEvent)
		{
			Marble.OnHitEvent(Hit);
		}
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
	void TickActive(float DeltaTime)
	{	
		// Physics it disabled on remote
		FVector Velocity = HasControl() ? Marble.ActualVelocity : Marble.GetPhysicalVelocity(); 
		
		Marble.CurrentVelocity = Velocity.Size();
		Marble.DeltaVelocity = (Marble.CurrentVelocity - Marble.LastFrameVelocity) / DeltaTime;
		Marble.LastFrameVelocity = Marble.CurrentVelocity;

		StoredVelocity = Velocity;

		TraceGround();
	}

	void TraceGround()
	{
		TArray<AActor> ActorArray;
		FHitResult HitResult;
		System::SphereTraceSingle(Marble.ActorLocation, FVector::UpVector * -20 + Marble.ActorLocation, 25.f, ETraceTypeQuery::Visibility, false, ActorArray, EDrawDebugTrace::None, HitResult, true);
		Marble.CurrentPhysicalMaterial = HitResult.PhysMaterial;
		Marble.CurrentHitResult = HitResult;
	}
}