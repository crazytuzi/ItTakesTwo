import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Shed.ToolBoxBoss.PlayerNailRainedComponent;
import Cake.LevelSpecific.Shed.ToolBoxBoss.ToolBoxNailRainNew;

struct FToolBoxNailRainGroupNail
{
	UPROPERTY(Meta = (MakeEditWidget))
	FVector Location;

	UPROPERTY(NotVisible)
	UStaticMeshComponent MeshComp;

	UPROPERTY(NotVisible)
	UDecalComponent Decal;

	UPROPERTY(NotVisible)
	UMaterialInstanceDynamic DecalMaterial;

	UPROPERTY(NotVisible)
	USceneComponent AttachComp;

	UPROPERTY(NotVisible)
	FVector AttachRelativeLocation;

	bool ShouldLand = true;
	
	float AnimTime;
}

struct FToolBoxNailRainGroup
{
	UPROPERTY()
	float AnimNailInterval = 0.05f;

	UPROPERTY()
	bool FirstNailHitGround = false;

	UPROPERTY()
	float AnimVariance = 0.1f;

	UPROPERTY()
	float FallTime = 1.5f;

	UPROPERTY()
	float GroundedDuration = 0.5f;

	UPROPERTY()
	TArray<FToolBoxNailRainGroupNail> Nails;

	int NumAnimatedNails = 0;

	UPROPERTY()
	TArray<ANiagaraActor> ImpactFXs;

	UPROPERTY()
	TArray<ANiagaraActor> OnStartFXs;
}

class AToolBoxNailRain : AHazeActor
{
	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(Category = "Groups")
	TArray<FToolBoxNailRainGroup> Groups;

	UPROPERTY(Category = "Visuals")
	UStaticMesh NailMesh;

	UPROPERTY(Category = "Visuals")
	UMaterialInterface DecalMaterial;

	UPROPERTY(Category = "Visuals")
	TArray<UAnimSequence> NailAnimations;

	UPROPERTY(Category = "Visuals")
	float NailMinSize = 5.f;

	UPROPERTY(Category = "Visuals")
	float NailMaxSize = 10.f;

	UPROPERTY(Category = "Visuals")
	float DecalSize;

	UPROPERTY(Category = "Damage")
	float HitRadius;
	float HitRadiusSqrd;

	UPROPERTY(Category = "Damage")
	float HitDamage = 0.5f;

	UPROPERTY(Category = "Damage")
	TSubclassOf<UPlayerDamageEffect> HitDamageEffect;

	float DealtDamageTimer_Cody = 0.f;
	float DealtDamageTimer_May = 0.f;

	UPROPERTY(Category = "Damage")
	float CollisionVerticalPadding = 200.f;

	UPROPERTY(Category = "FX")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(Category = "FX")
	UNiagaraSystem ImpactSystem;

	UPROPERTY(Category = "Animation")
	UCurveFloat DecalFadeCurve;

	UPROPERTY(Category = "Animation")
	float FallSpeed = 10000.f;

	UPROPERTY(Category = "Debug")
	TArray<UMaterialInstance> DebugMaterials;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ShootEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BurstEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent InComingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent InComingStopEvent;

	UPROPERTY()
	UPlayerNailRainedComponent NailRainComp;

	TArray<FNailAttachPlayer> NailAttachPlayerStructArray;

	bool bFirstImpactEvent = false;

	bool bFirstShotEvent = false;

	float GetDecalAlpha(float Time)
	{
		// This function samples a curve, but since the animation timer goes from MaxTime --> 0 --> (-)GroundedDuration
		//	we have to sample it backwards, and not if the AnimTime is greater than the length of the curve
		if (DecalFadeCurve == nullptr)
			return 0.f;

		float MinTime = 0.f;
		float MaxTime = 0.f;

		DecalFadeCurve.GetTimeRange(MinTime, MaxTime);
		
		if (Time < MinTime || Time >= MaxTime)
			return 0.f;

		// Invert the time, so that it starts sampling the curve at (AnimTime = MaxTime), and reaches the end of the curve at (AnimTime = 0)
		float RealTime = MaxTime - Time;
		return DecalFadeCurve.GetFloatValue(RealTime);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpdateNailAttachments();
		
		HitRadiusSqrd = FMath::Square(HitRadius);
		HideAllGroups();

		for(FToolBoxNailRainGroup& Group : Groups)
		{
			for(int i=0; i<Group.Nails.Num(); ++i)
			{
				FToolBoxNailRainGroupNail& Nail = Group.Nails[i];
				Nail.MeshComp.SetMaterial(0, NailMesh.GetMaterial(0));
			}
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		int GroupIndex = 0;
		for(FToolBoxNailRainGroup& Group : Groups)
		{
			for(int i=0; i<Group.Nails.Num(); ++i)
			{
				FToolBoxNailRainGroupNail& Nail = Group.Nails[i];

				// Spawn nail mesh and decal
				Nail.MeshComp = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent::StaticClass()));
				Nail.Decal = Cast<UDecalComponent>(CreateComponent(UDecalComponent::StaticClass()));

				// Randomize the skeletal mesh and set a random animation
				Nail.MeshComp.SetRelativeLocation(Nail.Location);
				Nail.MeshComp.SetRelativeScale3D(FVector::OneVector * FMath::RandRange(NailMinSize, NailMaxSize));
				Nail.MeshComp.SetRelativeRotation(FRotator(FMath::RandRange(-20.f, 20.f), FMath::RandRange(0.f, 360.f), FMath::RandRange(-20.f, 20.f)));
				Nail.MeshComp.SetStaticMesh(NailMesh);
				Nail.MeshComp.SetHiddenInGame(true);
				Nail.MeshComp.SetCastShadow(false);	

				Nail.MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

				// if (NailAnimations.Num() > 0)
				// {
				// 	Nail.MeshComp.AnimationMode = EAnimationMode::AnimationSingleNode;
				// 	Nail.MeshComp.AnimationData.AnimToPlay = NailAnimations[FMath::RandRange(0, NailAnimations.Num() - 1)];
				// }

				// Rotate decal so its facing up, and make the material dynamic
				Nail.Decal.SetRelativeLocation(Nail.Location);
				Nail.Decal.SetRelativeRotation(FRotator(90.f, 0.f, 0.f));
				Nail.Decal.SetDecalMaterial(DecalMaterial);
				Nail.Decal.DecalSize = FVector(150.f, DecalSize, DecalSize);
				Nail.DecalMaterial = Nail.Decal.CreateDynamicMaterialInstance();


				Nail.MeshComp.SetMaterial(0, DebugMaterials[GroupIndex % DebugMaterials.Num()]);
			}

			GroupIndex++;
		}
	}

	void UpdateNailAttachments()
	{
		for(FToolBoxNailRainGroup& Group : Groups)
		{			
			for(FToolBoxNailRainGroupNail& Nail : Group.Nails)
			{
				FVector WorldLocation = ActorTransform.TransformPosition(Nail.Location);

				FVector TraceStartLocation = WorldLocation + FVector::UpVector * 100.f;
				FVector TraceEndLocation = TraceStartLocation - FVector::UpVector * 150.f;
				// System::DrawDebugLine(TraceStartLocation, TraceEndLocation, FLinearColor::Blue, 5.f, 3.f);
				
				TArray<AActor> IgnoreActors;
				IgnoreActors.Add(this);
				FHitResult Hit;
				System::LineTraceSingle(TraceStartLocation, TraceEndLocation, ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, false);
				if (Hit.bBlockingHit)
				{
					Nail.ShouldLand = true;
					Nail.AttachComp = Hit.Component;
					Nail.AttachRelativeLocation = Hit.Component.WorldTransform.InverseTransformPosition(Hit.Location);
				}
				else
				{
					Nail.ShouldLand = false;
					Nail.AttachRelativeLocation = WorldLocation;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		DealtDamageTimer_Cody -= DeltaTime;
		DealtDamageTimer_May -= DeltaTime;

		UpdateAnimations(DeltaTime);
		
	}

	UFUNCTION()
	void HideAllGroups()
	{
		NailAttachPlayerStructArray.Empty();

		for(FToolBoxNailRainGroup& Group : Groups)
		{			
			for(FToolBoxNailRainGroupNail& Nail : Group.Nails)
			{
				Nail.MeshComp.SetHiddenInGame(true);
				Nail.Decal.SetHiddenInGame(true);
			}

			Group.NumAnimatedNails = 0;
		}

		bFirstImpactEvent = false;

		bFirstShotEvent = false;

	}

	UFUNCTION()
	void StartAnimatingGroup(int GroupIndex)
	{
		FToolBoxNailRainGroup& Group = Groups[GroupIndex];
		for(int i=0; i < Group.OnStartFXs.Num(); i++)
		{
			Group.OnStartFXs[i].NiagaraComponent.Activate();
		}
		Group.FirstNailHitGround = false;
		
		for(int i=0; i<Group.Nails.Num(); ++i)
		{
			FToolBoxNailRainGroupNail& Nail = Group.Nails[i];

			Nail.AnimTime = Group.FallTime + i * Group.AnimNailInterval + FMath::RandRange(-Group.AnimVariance, Group.AnimVariance);
			Nail.MeshComp.SetHiddenInGame(false);
			Nail.Decal.SetHiddenInGame(false);

		}

		Group.NumAnimatedNails = Group.Nails.Num();

		// Update one frame of animation because this function might be called after this actor has ticked
		//	and then the nails will be visible at their origin for 1 frame
		UpdateAnimationForGroup(Group, 0.f);
	}

	UFUNCTION()
	void UpdateAnimations(float DeltaTime)
	{
		for(FToolBoxNailRainGroup& Group : Groups)
		{
			UpdateAnimationForGroup(Group, DeltaTime);
		}
	}

	void UpdateAnimationForGroup(FToolBoxNailRainGroup& Group, float DeltaTime)
	{
		// Group is not animated
		if (Group.NumAnimatedNails <= 0)
			return;

		for(FToolBoxNailRainGroupNail& Nail : Group.Nails)
		{
			FVector TargetWorldLocation;
			if (Nail.ShouldLand)
			{
				TargetWorldLocation = Nail.AttachComp.WorldTransform.TransformPosition(Nail.AttachRelativeLocation);
			}
			else
			{
				TargetWorldLocation = Nail.AttachRelativeLocation - FVector::UpVector * 6000.f;
			}

			/* FALLING (positive animtime) */
			if (Nail.AnimTime > 0.f)
			{
				Nail.AnimTime -= DeltaTime;

				// Update nail position
				float Height = FallSpeed * Nail.AnimTime;
				Height = FMath::Max(Height, 0.f);

				FVector Offset = FVector::UpVector * Height;
				Nail.MeshComp.SetWorldLocation(TargetWorldLocation + Offset);

				// Update decal alpha
				float DecalAlpha = GetDecalAlpha(Nail.AnimTime);
				Nail.DecalMaterial.SetScalarParameterValue(n"ShadowSize", DecalAlpha);
				// Print(""+DecalAlpha);

				// Check for collisions after movement has been made
				UpdateNailPlayerDamage(Nail.MeshComp.WorldLocation, FallSpeed * DeltaTime, Nail.MeshComp);

				// Hit the ground this frame
				if (Nail.AnimTime <= 0.f)
				{
					OnImpact(Nail.MeshComp.GetWorldLocation());
					if(Group.FirstNailHitGround == false)
					{
						for(int i=0; i < Group.ImpactFXs.Num(); i++)
						{
							Group.ImpactFXs[i].NiagaraComponent.Activate();
						}
					}
					Group.FirstNailHitGround = true;
					Nail.Decal.SetHiddenInGame(true);


				}

				if(!bFirstShotEvent)
				{
					//Print("NailShotEvent");
					HazeAkComp.HazePostEvent(InComingEvent);
					HazeAkComp.HazePostEvent(ShootEvent);
					bFirstShotEvent = true;
				}

			}
			/* STUCK IN GROUND (negative animtime) */
			else if (Nail.AnimTime > -Group.GroundedDuration)
			{
				Nail.AnimTime -= DeltaTime;
				Nail.MeshComp.SetWorldLocation(TargetWorldLocation);

				if (Nail.AnimTime <= -Group.GroundedDuration)
				{
					// Disappear
					for (FNailAttachPlayer CurNailPlayerStruct : NailAttachPlayerStructArray)
					{
						if (CurNailPlayerStruct.NailMesh == Nail.MeshComp)
							CurNailPlayerStruct.Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
					}
					

					Nail.MeshComp.SetHiddenInGame(true);
					Nail.Decal.SetHiddenInGame(true);
					Group.NumAnimatedNails--;
				}
			}
		}
	}

	void OnImpact(FVector Location)
	{
		// Screen shake!
		AHazePlayerCharacter May;
		AHazePlayerCharacter Cody;
		Game::GetMayCody(May, Cody);

		HazeAkComp.HazePostEvent(ImpactEvent);

		May.PlayWorldCameraShake(CameraShakeClass, Location, 500.f, 1500.f, Scale = 1.5f);
		Cody.PlayWorldCameraShake(CameraShakeClass, Location, 500.f, 1500.f, Scale = 1.5f);

		if(!bFirstImpactEvent)
		{
			HazeAkComp.HazePostEvent(BurstEvent);
			HazeAkComp.HazePostEvent(InComingStopEvent);
			bFirstImpactEvent = true;
		}

	}

	
	void OnHitPlayer(AHazePlayerCharacter Player, UStaticMeshComponent NailMesh)
	{
		Player.DamagePlayerHealth(HitDamage, HitDamageEffect);

		//NailRainComp = UPlayerNailRainedComponent::Get(Player);
		//NailRainComp.PlayerWasHit = true;
		//NailRainComp.NailMesh = NailMesh;
		Player.AttachToComponent(NailMesh, NAME_None, EAttachmentRule::SnapToTarget);
		FNailAttachPlayer PlayerHitStruct;
		PlayerHitStruct.NailMesh = NailMesh;
		PlayerHitStruct.Player = Player;
		NailAttachPlayerStructArray.Add(PlayerHitStruct);

		if (Player.IsMay())
			DealtDamageTimer_May = 2.f;
		else
			DealtDamageTimer_Cody = 2.f;
	}

	
	bool CollidesWithPoint(FVector MyLocation, FVector Point, float FrameMove)
	{
		// Cylinder-point collision where the root of the cylinder is at the bottom, and the height is FrameMove
		// This is supposed to be called _after_ movement, so it checks retroactively if it moved through a player

		FVector HoriDiff;
		FVector VertDiff;
		Math::DecomposeVector(VertDiff, HoriDiff, Point - MyLocation, FVector::UpVector);

		// If the horizontal difference (sideways) is bigger than radius of cylinder, no collision
		if (HoriDiff.SizeSquared() > HitRadiusSqrd)
			return false;

		// I'm padding the values quite a bit here, since the player and nail is a lot bigger than mathematical points
		float VertDot = VertDiff.DotProduct(FVector::UpVector);
		if (VertDot < -CollisionVerticalPadding || VertDot > FrameMove + CollisionVerticalPadding)
			return false;

		return true;
	}

	void UpdateNailPlayerDamage(FVector Location, float FrameMove, UStaticMeshComponent NailMesh)
	{
		AHazePlayerCharacter May;
		AHazePlayerCharacter Cody;
		Game::GetMayCody(May, Cody);

		if (DealtDamageTimer_May < 0.f)
		{
			if (CollidesWithPoint(Location, May.ActorLocation, FrameMove))
				OnHitPlayer(May, NailMesh);
		}

		if (DealtDamageTimer_Cody < 0.f)
		{
			if (CollidesWithPoint(Location, Cody.ActorLocation, FrameMove))
				OnHitPlayer(Cody, NailMesh);
		}
	}

	UPROPERTY(EditConst)
	TSubclassOf<AToolBoxRainNailNew> NewNailClass = Asset("/Game/Blueprints/LevelSpecific/Shed/Mine/ToolBoxBoss/NailRainNew/BP_ToolBoxRainNailNew.BP_ToolBoxRainNailNew_C");

	UFUNCTION(CallInEditor, Category = "New System")
	void ReplaceWithNewRainSystem()
	{
		auto ControllerClass = AToolBoxRainControllerNew::StaticClass();
		auto GroupClass = AToolBoxRainGroupNew::StaticClass();

		auto Controller = Cast<AToolBoxRainControllerNew>(SpawnActor(ControllerClass));
		Controller.ActorLocation = ActorLocation;

		FTransform RootTransform = ActorTransform;

		for(auto GroupToCopy : Groups)
		{
			if (GroupToCopy.Nails.Num() == 0)
				continue;

			auto NewGroup = Cast<AToolBoxRainGroupNew>(SpawnActor(GroupClass));
			NewGroup.AttachRootComponentToActor(Controller);
			NewGroup.FallTime = GroupToCopy.FallTime;
			NewGroup.NailInterval = GroupToCopy.AnimNailInterval;
			NewGroup.NailIntervalVariance = GroupToCopy.AnimVariance;

			FVector MinPosition = GroupToCopy.Nails[0].Location;
			FVector MaxPosition = GroupToCopy.Nails[0].Location;
			for(auto NailToCopy : GroupToCopy.Nails)
			{
				MinPosition = MinPosition.ComponentMin(NailToCopy.Location);
				MaxPosition = MaxPosition.ComponentMax(NailToCopy.Location);
			}

			FVector Centroid = MinPosition + (MaxPosition - MinPosition) * 0.5f;
			NewGroup.ActorLocation = RootTransform.TransformPosition(Centroid);

			for(auto NailToCopy : GroupToCopy.Nails)
			{
				auto NewNail = Cast<AToolBoxRainNailNew>(SpawnActor(NewNailClass));
				NewNail.AttachRootComponentToActor(NewGroup);
				NewNail.ActorLocation = RootTransform.TransformPosition(NailToCopy.Location);
			}
		}

		Controller.UpdateGroups();
	}
}

struct FNailAttachPlayer
{
	UStaticMeshComponent NailMesh;
	AHazePlayerCharacter Player;
}