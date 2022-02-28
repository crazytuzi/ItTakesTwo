import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballInteractions.SnowmanBreakableActor;

class AHittableIcicle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent IcicleComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	USnowballFightResponseComponent ResponseComp;

	FHazeTraceParams TraceParams;

	FVector FallLoc;

	FHazeAcceleratedFloat AccelFloat;

	float fallSpeed;
	float MaxFallSpeed = -3000.f;

	bool bCanFall;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnSnowballHit.AddUFunction(this, n"SnowBallHit");

		TraceParams.InitWithCollisionProfile(n"BlockAll");
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		TraceParams.IgnorePrimitive(IcicleComp);

		TraceParams.IgnorePrimitive(Game::May.Mesh);
		TraceParams.IgnorePrimitive(Game::Cody.Mesh);

		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");

		AccelFloat.SnapTo(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// FHazeHitResult Hit;

		// if (TraceParams.Trace(Hit))
		// {
		// 	PrintToScreen("Name: " + Hit.Actor.Name);
		// }

		if (!bCanFall)
			return;

		AccelFloat.AccelerateTo(MaxFallSpeed, 1.f, DeltaTime);
		AddActorWorldOffset(FVector(0.f, 0.f, AccelFloat.Value * DeltaTime));

		float Distance = (ActorLocation - FallLoc).Size();

		if (Distance < 30.f)
			bCanFall = false;
	}

	UFUNCTION()
	void SnowBallHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		TraceParams.From = ActorLocation;
		TraceParams.To = ActorLocation + FVector(0.f, 0.f, -4500.f);

		FHazeHitResult HazeHit;

		if (TraceParams.Trace(HazeHit))
		{
			FallLoc = HazeHit.ImpactPoint;
		}

		bCanFall = true;
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
			KillPlayer(Player);
		
		ASnowmanBreakableActor BreakableSnowActor = Cast<ASnowmanBreakableActor>(OtherActor);

		if (BreakableSnowActor != nullptr)
			BreakableSnowActor.OnActorExternalHit();
    }
}