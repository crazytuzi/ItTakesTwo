import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Peanuts.Audio.AudioStatics;

TArray<AHittableSignSwinging> GetAllHittableSigns()
{
	TArray<AHittableSignSwinging> HittableSignsArray;
	GetAllActorsOfClass(HittableSignsArray);
	return HittableSignsArray;
}

class AHittableSignSwinging : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TopSignAnchor;

	UPROPERTY(DefaultComponent)
	USnowballFightResponseComponent SnowBallResponseComp;

	UPROPERTY(DefaultComponent, Attach = TopSignAnchor)
	UStaticMeshComponent SignConnector1;
	default SignConnector1.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = TopSignAnchor)
	UStaticMeshComponent SignConnector2;
	default SignConnector2.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = TopSignAnchor)
	UStaticMeshComponent SignTop;
	default SignTop.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayWooshAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopWooshAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactAudioEvent;

	float Power;
	float SnowBallPower = 280.f;

	float Drag = 0.6f;

	float Gravity = 800.f;	

	bool bSignIsMoving = false;

	UFUNCTION(BlueprintOverride)	
	void BeginPlay()
	{
		SnowBallResponseComp.OnSnowballHit.AddUFunction(this, n"OnSnowBallHit");
	
		int NetworkIndex = 0;
		FNetworkIdentifierPart Identity;

		for (AHittableSignSwinging Sign : GetAllHittableSigns())
		{
			if (this == Sign)
			{
				Identity.Index = NetworkIndex;
				Print("NetworkIndex: " + NetworkIndex);
			}
			
			NetworkIndex++;
		}

		MakeNetworked(Identity);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Power -= Power * Drag * DeltaTime; 

		//Used to get the direction I.E. either positive or negative depending on which way the swing is rotated
		float DirectionDot = TopSignAnchor.ForwardVector.DotProduct(FVector::UpVector);

		//multipliy by directiondot to get the value that will be subtracted (or added if negative) onto power
		float CurrentGravity = Gravity * DirectionDot;
		Power -= CurrentGravity * DeltaTime;

		float FinalPower = Power * DeltaTime;
		TopSignAnchor.AddLocalRotation(FRotator(FinalPower, 0.f, 0.f));

		// AUDIO
		float NormalizedGravity = HazeAudio::NormalizeRTPC01(FMath::Abs(CurrentGravity), 0.f, 800.f);
		HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Snowglobe_Interactions_HittableSigns_Rotation", NormalizedGravity);
		
		if(bSignIsMoving && CurrentGravity == 0.f)
		{
			HazeAkComp.HazePostEvent(StopWooshAudioEvent);
			bSignIsMoving = false;
		}
	}

	UFUNCTION()
	void OnSnowBallHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		FVector Velocity = HitVelocity.GetSafeNormal();
		float AngledDot = SignTop.ForwardVector.DotProduct(-Velocity);
		Power += SnowBallPower * AngledDot; 
		HazeAkComp.HazePostEvent(ImpactAudioEvent);

		if(!bSignIsMoving)
		{
			HazeAkComp.HazePostEvent(PlayWooshAudioEvent);
		}
		bSignIsMoving = true;
	}
}