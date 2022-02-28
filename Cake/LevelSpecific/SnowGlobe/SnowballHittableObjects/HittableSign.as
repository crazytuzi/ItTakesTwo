import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;
import Peanuts.Audio.AudioStatics;

TArray<AHittableSign> GetAllHittableSigns()
{
	TArray<AHittableSign> HittableSignsArray;
	GetAllActorsOfClass(HittableSignsArray);
	return HittableSignsArray;
}

class AHittableSign : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TopSignAnchor;

	UPROPERTY(DefaultComponent)
	USnowballFightResponseComponent SnowBallResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SignBase;
	default SignBase.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = TopSignAnchor)
	UStaticMeshComponent SignTop;
	default SignBase.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = SignTop)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayWooshAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopWooshAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactAudioEvent;

	float RotationPower;
	float MaxRotationPower = 700.f;
	float NewRotPower;

	float SpinDrag = 0.55f;
	

	bool bSignIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		int NetworkIndex = 0;
		FNetworkIdentifierPart Identity;

		for (AHittableSign Sign : GetAllHittableSigns())
		{
			if (this == Sign)
			{
				Identity.Index = NetworkIndex;
				Print("NetworkIndex: " + NetworkIndex);
			}

			NetworkIndex++;
		}

		MakeNetworked(Identity);

		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnSignOverlap");
		SnowBallResponseComp.OnSnowballHit.AddUFunction(this, n"OnSnowBallHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		RotationPower -= RotationPower * SpinDrag * DeltaTime; 
		NewRotPower = RotationPower * DeltaTime;
		TopSignAnchor.AddWorldRotation(FRotator(0.f, NewRotPower, 0.f));
		
		// AUDIO
		float NormalizedRotation = HazeAudio::NormalizeRTPC01(FMath::Abs(RotationPower), 0.f, 800.f);
		//float NormalizedRotation = FMath::Abs(FMath::GetMappedRangeValueClamped(FVector2D(-800.f, 800.f), FVector2D(-1.f, 1.f), RotationPower));
		
		HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Snowglobe_Interactions_HittableSigns_Rotation", NormalizedRotation);
		
		if(bSignIsMoving && RotationPower == 0.f)
		{
			HazeAkComp.HazePostEvent(StopWooshAudioEvent);
			bSignIsMoving = false;
		}


	}

	UFUNCTION()
	void OnSnowBallHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		FVector Right = FVector::UpVector.CrossProduct(HitVelocity).GetSafeNormal();
		FVector ToProjectile = (Hit.Location - TopSignAnchor.WorldLocation).GetSafeNormal();
		float DirectionDot = Right.DotProduct(ToProjectile);
		DirectionDot = FMath::Sign(-DirectionDot);

		FVector Velocity = HitVelocity.GetSafeNormal();

		float AngledDot = TopSignAnchor.ForwardVector.DotProduct(Velocity);

		FVector NewForward = TopSignAnchor.ForwardVector;
		AngledDot *= FMath::Sign(AngledDot);
		
		RotationPower += MaxRotationPower * DirectionDot * AngledDot; 

		HazeAkComp.HazePostEvent(ImpactAudioEvent);

		if(!bSignIsMoving)
		{
			HazeAkComp.HazePostEvent(PlayWooshAudioEvent);
		}
		bSignIsMoving = true;
	}
	
	UFUNCTION()
    void OnSignOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
        AHazePlayerCharacter Player;
        Player = Cast<AHazePlayerCharacter>(OtherActor);
        
		if (Player != nullptr && NewRotPower > 1.5f)
        {
			FVector Dir = Player.ActorLocation - ActorLocation;
			Dir.Normalize();
			FVector KnockImpulse = Dir * 650.f;

			Player.KnockdownActor(KnockImpulse);
        }
    }

	// UFUNCTION()
    // void OnSignOverlap(UPrimitiveComponent HitComponent, AActor OtherActor, 
    // UPrimitiveComponent OtherComponent, FVector NormalImpulse, FHitResult& Hit)
    // {
    //     AHazePlayerCharacter Player;
    //     Player = Cast<AHazePlayerCharacter>(OtherActor);
        
	// 	Print("HIT");
		
	// 	if (Player != nullptr && NewRotPower > 1.f)
    //     {
	// 		FVector KnockImpulse = Hit.ImpactNormal * 250.f;
	// 		Player.KnockdownActor(KnockImpulse);
    //     }
    // }
}