import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneMagnet;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneWreckingBall;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleCourtyardCraneActor;

struct FCourtyardJengaPiece
{
	FCourtyardJengaPiece(UStaticMeshComponent InMesh)
	{
		Mesh = InMesh;
	}

	UStaticMeshComponent Mesh;
	FVector InitialLocation;
	float DelayUntilShrink = 0.f;
	float RandomValue;
	bool bCanBeDestroyed = false;
	bool bDestroyed = false;
}


class AJengaTowerBase : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent Box;
	
    UPROPERTY()
	UStaticMesh Mesh;
	
    UPROPERTY()
	float Scale = 4.0f;
	
    UPROPERTY(Meta = (MakeEditWidget))
	FVector Height = FVector(0, 0, 2000);

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float MissingPieces = 0.1f;
	
    UPROPERTY()
	float Untidyness = 10.0f;

    UPROPERTY()
	TArray<FCourtyardJengaPiece> JengaPieces;

    UPROPERTY()
	UNiagaraSystem BrickRemoveEffect;

	UPROPERTY()
	UCurveFloat BlockSizeChangeCurve;

	UPROPERTY()
	float ShrinkTime = 0.65f;

    UPROPERTY()
	float BrickDestroyDelayMin = 7.0f;
    UPROPERTY()
	float BrickDestroyDelayMax = 9.0f;

	float CurrentWobbleTime = 0;
	float WobbleTime = 0;
	float WobbleDistance = 0;
	FVector WobbleDirection;

	void Wobble(FVector WobbleDirection, float Wobbletime = 0.25f, float WobbleDistance = 100.0f)
	{
		this.WobbleTime = Wobbletime;
		this.CurrentWobbleTime = Wobbletime;
		this.WobbleDistance = WobbleDistance;
		this.WobbleDirection = WobbleDirection;
	}

    UFUNCTION(CallInEditor)
	void WobbleEditor()
	{
		WobbleTime = 0.25f;
		CurrentWobbleTime = WobbleTime;
		WobbleDistance = 100;
		WobbleDirection = FVector(1, 0, 0);
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		SetActorScale3D(FVector(1, 1, 1));
		SetActorRotation(FRotator(0, GetActorRotation().Yaw, 0));
		Height = FVector(0, 0, Height.Z);

		JengaPieces.Empty();

		int Pieces = FMath::TruncToInt(Height.Z / (Scale * 23.8f));

		bool EveryOtherIndex = false;
		for (int i = 0; i < Pieces; i++)
		{
			float CurrentHeight = float(i) / float(Pieces - 1);
			// Generate a random value between -1 and +1 based on user slider and height so pieces lower down are less likely to be missing.
			int MissingPieceIndex = (FMath::FRand() < (MissingPieces * CurrentHeight)) ? FMath::RandRange(-1, 1) : 999;
			EveryOtherIndex = !EveryOtherIndex;
			
			for (int j = -1; j <= 1; j++) // -1, 0, 1
			{
				if(MissingPieceIndex == j)
					continue;

				auto NewMesh = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent::StaticClass()));
				NewMesh.BodyInstance.bNotifyRigidBodyCollision = true;
				NewMesh.BodyInstance.PositionSolverIterationCount = 8;
				NewMesh.BodyInstance.bOverrideMaxDepenetrationVelocity = true;
				NewMesh.BodyInstance.MaxDepenetrationVelocity = 0;
				NewMesh.SetbCastDynamicShadow(false);

				NewMesh.StaticMesh = Mesh;
				NewMesh.CollisionProfileName = n"PhysicsBody";
				NewMesh.SetCollisionObjectType(ECollisionChannel::ECC_PhysicsBody);
				NewMesh.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
				NewMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Block);
				NewMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
				NewMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Block);
				NewMesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
			
				float OutOffset = j * (Scale * 50.0f + FMath::FRand() * Untidyness * Scale);
				float SideOffset = FMath::FRand() * Untidyness * Scale;

				FVector Position = FVector(EveryOtherIndex ? SideOffset : OutOffset, 
										   EveryOtherIndex ? OutOffset : SideOffset, 
										   i * Scale * 23.8f);

				FRotator Rotation = FRotator(0, EveryOtherIndex ? 0 : 90, 0);
				NewMesh.SetRelativeTransform(FTransform(Rotation, Position, FVector(Scale, Scale, Scale)));

				NewMesh.SetSimulatePhysics(true);

				FCourtyardJengaPiece Piece;
				Piece.Mesh = NewMesh;
				Piece.RandomValue = FMath::FRand();
				Piece.DelayUntilShrink = -FMath::Lerp(BrickDestroyDelayMin, BrickDestroyDelayMax, Piece.RandomValue);
				JengaPieces.Add(Piece);
			}
		}

		FVector BoxLocation = ActorLocation + (FVector::UpVector * Height / 2.f);
		Box.SetWorldLocation(BoxLocation);
		Box.SetRelativeRotation(FRotator());
		float HorizontalScale = Scale * 85.0f;
		float VerticalScale = (Height.Z / 2.f) + 5.f;
		Box.SetBoxExtent(FVector(HorizontalScale, HorizontalScale, VerticalScale));
	}

	void DestroyBrick(int i)
	{
		JengaPieces[i].bDestroyed = true;
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		SleepDelay = 4.0f;
		for (int i = 0; i < JengaPieces.Num(); i++)
		{
			//JengaPieces[i].Mesh.SetGenerateOverlapEvents(true);
			JengaPieces[i].Mesh.OnComponentHit.AddUFunction(this, n"JengaHit");
		}

		if(DebugShowCollisionHistogram)
		{
			JengaCollisionHistogram = TArray<float>();
			JengaCollisionHistogram.SetNumZeroed(HistogramMax);
		}

		// Freeze everything
		for (int i = 0; i < JengaPieces.Num(); i++)
		{
			if(JengaPieces[i].Mesh == nullptr)
				continue;
			JengaPieces[i].Mesh.PutRigidBodyToSleep();
			JengaPieces[i].Mesh.SetSimulatePhysics(false);
			JengaPieces[i].InitialLocation = JengaPieces[i].Mesh.WorldLocation;
			JengaPieces[i].bCanBeDestroyed = true;
		}
	}

	// Debugging histogram to see the forces at play. The range is 0 - 1 000 000
	UPROPERTY(Category="Sound")
	bool DebugShowCollisionHistogram = false;

	// Draws a white dot and prints to the screen whenever a sound is played.
	UPROPERTY(Category="Sound")
	bool DebugShowCollisionSoundEvents = false;
	
	UPROPERTY(Category="Sound")
	UAkAudioEvent JengaBlockSelfCollisionSoundEvent;
	
	UPROPERTY(Category="Sound")
	UAkAudioEvent JengaBlockWorldCollisionSoundEvent;
	
	UPROPERTY(Category="Sound")
	UAkAudioEvent JengaBlockWreckingBallCollisionSoundEvent;

	// Percentage of hit events that play a sound.
	UPROPERTY(Category="Sound")
	float WorldCollisionSoundHitFilterPercentage = 25.0f;

	UPROPERTY(Category="Sound")
	float SelfCollisionSoundHitFilterPercentage = 0.1f;

	UPROPERTY(Category="Sound")
	float WreckingBallCollisionSoundHitFilterPercentage = 0.5f;

	// Not currently in-use
	//UPROPERTY(Category="Sound")
	//float MaxVelocityForce = 600;

	// Fired when the tower falls
	UPROPERTY(Category="Sound")
	UAkAudioEvent JengaTowerFallSoundEvent;

	UPROPERTY(Category="Sound")
	float MaxSoundHitForce = 600000;

	// If the velocity is below this value, it is ignored.
	UPROPERTY(Category="Sound")
	float SmallestSoundVelocity = 50;

	// If the normalized hit force is below this value, it is ignored.
	UPROPERTY(Category="Sound")
	float SmallestSoundForce = 0.01;

	UPROPERTY(Category="Sound")
	AActor CourtyardCraneWreckingBall;

	TArray<float> JengaCollisionHistogram;
	float SleepDelay = 4.0f;
	bool BricksCanPlaySound = false;
	float HistogramMax = 1000;
	
	int JengaPiecesPushedOverCount = 0;
	bool PushedOverEventFired = false;

    UFUNCTION()
	void JengaHit(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComp, FVector NormalImpulse, FHitResult& InHit)
	{
		if(BricksCanPlaySound)
		{
			float HitForce = NormalImpulse.Size();
			float Velocity = HitComponent.GetComponentVelocity().Size();

			float NormalizedHitForce = FMath::Clamp(HitForce / MaxSoundHitForce, 0.0, 1.0);
			//float NormalizedVelocity = FMath::Clamp(Velocity / MaxVelocityForce, 0.0, 1.0);
			float SoundHitFilterPercentage = 0;
			UAkAudioEvent JengaBlockCollisionSoundEvent = nullptr;

			bool SelfCollision = OtherActor == this;
			bool WreckingBallCollission = OtherActor == CourtyardCraneWreckingBall;
			
			if(SelfCollision)
			{
				SoundHitFilterPercentage = SelfCollisionSoundHitFilterPercentage;
				JengaBlockCollisionSoundEvent = JengaBlockSelfCollisionSoundEvent;
			}
			else if (WreckingBallCollission)
			{
				SoundHitFilterPercentage = WreckingBallCollisionSoundHitFilterPercentage;
				JengaBlockCollisionSoundEvent = JengaBlockWreckingBallCollisionSoundEvent;
			}
			else
			{
				if(PushedOverEventFired)
				{
					SoundHitFilterPercentage = WorldCollisionSoundHitFilterPercentage;
					JengaBlockCollisionSoundEvent = JengaBlockWorldCollisionSoundEvent;
				}
				else
				{
					Velocity = 0;
				}
			}
			
			if(DebugShowCollisionHistogram)
			{
				if(Velocity < HistogramMax) // It's off the charts! Litterally!
					JengaCollisionHistogram[Velocity] += 1.0f;
			}
			
			if(FMath::RandRange(0.0f, 100.0f) < SoundHitFilterPercentage && 
					Velocity > SmallestSoundVelocity && 
					NormalizedHitForce > SmallestSoundForce &&
					HitComponent.GetRelativeScale3D().X == Scale) // Don't play any sounds if the mesh is shrinking.
			{
				TMap<FString, float> Rtpcs;
				Rtpcs.Add("Rtpc_Castle_Courtyard_Destructible_JengaBlock_ImpactForce", NormalizedHitForce);
				if(JengaBlockCollisionSoundEvent != nullptr)
					UHazeAkComponent::HazePostEventFireForgetWithRtpcs(JengaBlockCollisionSoundEvent, FTransform(InHit.Location), Rtpcs);

				if(DebugShowCollisionSoundEvents)
				{
					PrintToScreenScaled(("NormalizedHitForce " + NormalizedHitForce), 1.f, FLinearColor :: LucBlue, Scale = 1.f);
					PrintToScreenScaled(("Velocity " + Velocity), 1.f, FLinearColor :: LucBlue, Scale = 1.f);
					System::DrawDebugPoint(InHit.Location, 10, FLinearColor::White, 2.0f);
				}
			}
		}
		AJengaTowerBase Tower = Cast<AJengaTowerBase>(OtherActor);
		if(Tower != nullptr) // we were hit by a tower, unfreeze
		{
			Unfreeze();
		}
		PostJengaHit(HitComponent, OtherActor, OtherComp, NormalImpulse, InHit);
	}

	void PostJengaHit(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComp, FVector NormalImpulse, FHitResult& InHit)	{}

	bool frozen = true;

    UFUNCTION(CallInEditor)
	void Unfreeze()
	{
		if (!HasControl())
			return;

		if(!frozen)
			return;

		NetUnfreeze();
	}

	UFUNCTION(NetFunction)
	void NetUnfreeze()
	{
		UnfreezeInternal();
	}

	void UnfreezeInternal()
	{
		BricksCanPlaySound = true;
		frozen = false;
		
		for (int i = 0; i < JengaPieces.Num(); i++)
		{
			if(JengaPieces[i].Mesh != nullptr)
			{
				JengaPieces[i].Mesh.SetSimulatePhysics(true);
			}
		}
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {

		if(DebugShowCollisionHistogram)
		{
			for (int i = 0; i < JengaCollisionHistogram.Num(); i++)
			{	
				FVector Offset = GetActorLocation() + (-GetActorRightVector() * 1500) + (-GetActorForwardVector() * i * 2) + (GetActorForwardVector() * JengaCollisionHistogram.Num() * 2 * 0.5);
				DebugDrawLine(Offset, Offset + (FVector::UpVector * JengaCollisionHistogram[i] * 0.1));
			}
		}

		for (int i = 0; i < JengaPieces.Num(); i++)
		{
			if(JengaPieces.Num() == 0)
				continue;

			if(JengaPieces[i].Mesh == nullptr)
				continue;

			if (!JengaPieces[i].bCanBeDestroyed)
				continue;

			if (!JengaPieces[i].bDestroyed)
			{
				float DistanceToInitial = (JengaPieces[i].Mesh.WorldLocation - JengaPieces[i].InitialLocation).Size();
				if (DistanceToInitial > 250.f)
				{	
					DestroyBrick(i);
					JengaPieces[i].Mesh.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
					JengaPieces[i].bDestroyed = true;
					JengaPiecesPushedOverCount++;
				}
			}

			if(JengaPieces[i].bDestroyed)
			{
				JengaPieces[i].DelayUntilShrink += DeltaTime;
				if(JengaPieces[i].DelayUntilShrink >= 0.f && JengaPieces[i].DelayUntilShrink < ShrinkTime) // If it's shrinking
				{
					float FadeScale = Scale * (1 - FMath::Clamp((JengaPieces[i].DelayUntilShrink / ShrinkTime), 0.f, 1.f));				
					JengaPieces[i].Mesh.SetRelativeScale3D(FVector(FadeScale, FadeScale, FadeScale));
				}
				else if(JengaPieces[i].DelayUntilShrink >= ShrinkTime && JengaPieces[i].Mesh != nullptr) // When it's done shrinking
				{
					if(BrickRemoveEffect != nullptr)
						Niagara::SpawnSystemAtLocation(BrickRemoveEffect, JengaPieces[i].Mesh.GetWorldLocation(), JengaPieces[i].Mesh.GetWorldRotation());

					JengaPieces[i].Mesh.DestroyComponent(JengaPieces[i].Mesh);
				}					
			}
		}

		if(CurrentWobbleTime > 0)
		{
			CurrentWobbleTime -= DeltaTime;
			for (int i = 0; i < JengaPieces.Num(); i++)
			{
				if (JengaPieces[i].Mesh == nullptr)
					continue;

				float NormalizedWobbleTime = FMath::Clamp(CurrentWobbleTime / WobbleTime, 0.0f, 1.0f);
				float WobbleOffset = 1.0f - ((1.0f - (NormalizedWobbleTime * 2.0f)) * (1.0f - (NormalizedWobbleTime * 2.0f)));
				
				// Secret way to set material parameters without making a dynamic material. ssshhhhhh...
				JengaPieces[i].Mesh.SetCustomPrimitiveDataVector4(0, FVector4(WobbleDirection.X, WobbleDirection.Y, WobbleDirection.Z, WobbleOffset * WobbleDistance * JengaPieces[i].RandomValue));
				
			}
		}
		else if(CurrentWobbleTime < 0)
		{
			CurrentWobbleTime = 0;
			for (int i = 0; i < JengaPieces.Num(); i++)
			{
				JengaPieces[i].RandomValue = FMath::FRand();
			}
		}

		// Event when the tower is pushed over.
		if(!PushedOverEventFired && JengaPiecesPushedOverCount > (JengaPieces.Num() / 2))
		{
			PushedOverEventFired = true;

			if(JengaTowerFallSoundEvent != nullptr)
				UHazeAkComponent::HazePostEventFireForget(JengaTowerFallSoundEvent, FTransform(GetActorLocation()));
		}
	}
}

class APhysicsJengaTower : AJengaTowerBase
{
	float JengaHitCooldown = 0.1f;
	float JengaHitDuration = 0.1f;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;

    UPROPERTY()
	float DestroyHeight = -200.0f;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Super::ConstructionScript();
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Super::BeginPlay();
		
		Box.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	void PostJengaHit(UPrimitiveComponent HitComponent, AActor OtherActor, UPrimitiveComponent OtherComp, FVector NormalImpulse, FHitResult& InHit) override
	{

		ACourtyardCraneWreckingBall WreckingBall = Cast<ACourtyardCraneWreckingBall>(OtherActor);
		if (WreckingBall == nullptr)
			return;

		if (JengaHitDuration < JengaHitCooldown)
			return;
		JengaHitDuration = 0.f;

		FVector JengaVelocity = HitComponent.ComponentVelocity;	
		FVector VelocityDelta = JengaVelocity - WreckingBall.LinearVelocity;

		FVector ToWreckingBallDirection = (OtherActor.ActorLocation - HitComponent.WorldLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		float SpeedTowardsWreckingBall = FMath::Max(ToWreckingBallDirection.DotProduct(VelocityDelta), 0.f);

		FVector Impulse = ToWreckingBallDirection.CrossProduct(FVector::UpVector) * SpeedTowardsWreckingBall * 0.00034f;
		WreckingBall.AngularVelocity += Impulse;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (WreckingBall.PlayersInteractingWithCrane[Player])
				Player.PlayForceFeedback(WreckingBall.HitDoorForceFeedback, false, false, NAME_None, Impulse.Size() * 2.f);
		}
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		Super::Tick(DeltaTime);
		
		JengaHitDuration += DeltaTime;

		// Destroy when below a certain height
		for (int i = 0; i < JengaPieces.Num(); i++)
		{
			if(JengaPieces[i].Mesh == nullptr)
				continue;
			
			if(JengaPieces[i].Mesh.GetWorldLocation().Z < (GetActorLocation().Z + DestroyHeight))
			{
				DestroyBrick(i);
			}
		}
	}

	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		ACourtyardCraneMagnet Magnet = Cast<ACourtyardCraneMagnet>(OtherActor);
		if (Magnet != nullptr)
		{
			float Speed = Magnet.AngularVelocity.Size();
			FVector Direction = FVector::UpVector.CrossProduct(Magnet.AngularVelocity).GetSafeNormal();
			Wobble(Direction, 0.1f, 12.5f * Speed);		

			Magnet.AngularVelocity = -Magnet.AngularVelocity * 0.4f;

			return;
		}

		ACourtyardCraneWreckingBall WreckingBall = Cast<ACourtyardCraneWreckingBall>(OtherActor);
		if (WreckingBall != nullptr)
		{
			ACastleCourtyardCraneActor Crane = Cast<ACastleCourtyardCraneActor>(WreckingBall.CraneActorRef);
			if (Crane != nullptr)
			{
				if (Crane.PlayerRotatingCrane != nullptr)
				{
					if (Crane.PlayerRotatingCrane.IsMay())
						PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleCourtyardWreckingBallDestroyMay");
					else
						PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleCourtyardWreckingBallDestroyCody");
				}
			}

			Box.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			Unfreeze();
		}
	}
}