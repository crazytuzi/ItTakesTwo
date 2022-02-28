import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Replication Input Actor LOD Cooking")
class AStarBuddy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent StarRoot;

	UPROPERTY(DefaultComponent, Attach = StarRoot)
	UStaticMeshComponent StarMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem SupernovaEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> SupernovaCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SupernovaForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh SurprisedMesh;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayAnimation;
	
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyAnimation;

	FHazeAnimNotifyDelegate AnimNotifyDelegate;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike HoverTimelike;

	UPROPERTY(Category = "Properties")
	float MaxRotationRate = 80.f;
	FRotator RotationRate;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BuddyActivateAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayIdleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopIdleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopBuddyActivateAudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayPoofAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayExplodeAudioEvent;

	bool bSlapped = false;

	FVector SlapDirection = FVector::ZeroVector;

	float TravelTime = 0.f;
	float MaxTravelTime = 2.f;

	TArray<AActor> ActorsToIgnore;

	AHazePlayerCharacter SlappingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		float Pitch = FMath::RandRange(-MaxRotationRate, MaxRotationRate);
		float Yaw = FMath::RandRange(-MaxRotationRate, MaxRotationRate);
		float Roll = FMath::RandRange(-MaxRotationRate, MaxRotationRate);
		RotationRate = FRotator(Pitch, Yaw, Roll);

		HoverTimelike.SetPlayRate(0.25f);
		HoverTimelike.BindUpdate(this, n"UpdateHover");

		float HoverDelay = FMath::RandRange(0.1f, 3.f);
		System::SetTimer(this, n"StartHovering", HoverDelay, false);

		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");

		HazeAkComp.HazePostEvent(PlayIdleAudioEvent);

		TArray<AStarBuddy> AllStars;
		GetAllActorsOfClass(AllStars);
		for (AStarBuddy Star : AllStars)
		{
			ActorsToIgnore.Add(Star);
		}

		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());
	}

	UFUNCTION(NotBlueprintCallable)
	void StartHovering()
	{
		HoverTimelike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateHover(float CurValue)
	{
		float CurHeight = FMath::Lerp(180.f, 250.f, CurValue);
		StarRoot.SetRelativeLocation(FVector(0.f, 0.f, CurHeight));

		FHazeTriggerVisualSettings VisualSettings;
		VisualSettings.VisualOffset.Location = FVector(0.f, 0.f, CurHeight);
		InteractionComp.SetVisualSettings(VisualSettings);
	}

	UFUNCTION(NotBlueprintCallable)
    void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionComp.Disable(n"Slapped");

		if (Player.HasControl())
		{
			FVector DirToPlayer = Player.ActorLocation - ActorLocation;
			DirToPlayer = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
			DirToPlayer = DirToPlayer.GetSafeNormal();
			SlapDirection = -DirToPlayer;

			FVector SlapLocation = ActorLocation + (DirToPlayer * 100.f);
			
			UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
			FHazeCrumbDelegate CrumbDelegate;
			CrumbDelegate.BindUFunction(this, n"Crumb_SlapStarBuddy");
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddVector(n"SlapLocation", SlapLocation);
			CrumbParams.AddVector(n"SlapDirection", SlapDirection);
			CrumbParams.AddObject(n"Player", Player);
			CrumbComp.LeaveAndTriggerDelegateCrumb(CrumbDelegate, CrumbParams);
		}
    }

	UFUNCTION(NotBlueprintCallable)
	void Crumb_SlapStarBuddy(FHazeDelegateCrumbData CrumbData)
	{
		SlappingPlayer = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		if (SlappingPlayer.IsCody())
			ForceCodyMediumSize();

		AnimNotifyDelegate.BindUFunction(this, n"StarBuddySlapped");
        SlappingPlayer.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);
		
		UAnimSequence Animation = SlappingPlayer.IsMay() ? MayAnimation : CodyAnimation;
		SlappingPlayer.PlayEventAnimation(Animation = Animation);

		FVector SlapLocation = CrumbData.GetVector(n"SlapLocation");
		FRotator SlapRotation = SlapDirection.Rotation();
		SlapDirection = CrumbData.GetVector(n"SlapDirection");

		FHazePointOfInterest PointOfInterestSettings;
		PointOfInterestSettings.Duration = 1.f;
		PointOfInterestSettings.Blend.BlendTime = 0.6f;
		PointOfInterestSettings.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		PointOfInterestSettings.FocusTarget.WorldOffset = ActorLocation + (SlapDirection * 1500.f);
		SlappingPlayer.ApplyPointOfInterest(PointOfInterestSettings, this);

		SlappingPlayer.SmoothSetLocationAndRotation(SlapLocation, SlapRotation);
		DisableComponent.SetUseAutoDisable(false);

		HazeAkComp.HazePostEvent(BuddyActivateAudioEvent);
		HazeAkComp.HazePostEvent(StopIdleAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void StarBuddySlapped(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);

		SetActorEnableCollision(false);
		
		if (SurprisedMesh != nullptr)
			StarMesh.SetStaticMesh(SurprisedMesh);

		RotationRate *= 10.f;
		bSlapped = true;

		BP_Slapped();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Slapped() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		StarRoot.AddLocalRotation(RotationRate * DeltaTime);

		if (!bSlapped)
			return;

		AddActorWorldOffset(SlapDirection * 4000.f * DeltaTime);

		FHitResult Hit;
		System::SphereTraceSingle(StarRoot.WorldLocation, StarRoot.WorldLocation + FVector(0.f, 0.f, 1.f), 90.f, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		if (Hit.bBlockingHit)
			ExplodeStarBuddy();
			
		TravelTime += DeltaTime;
		if (TravelTime >= MaxTravelTime)
		{
			TriggerSupernova();
		}
	}

	void ExplodeStarBuddy()
	{
		Niagara::SpawnSystemAtLocation(ExplosionEffect, StarRoot.WorldLocation);
		HazeAkComp.HazePostEvent(StopBuddyActivateAudioEvent);
		DisableStarBuddy();
		UHazeAkComponent::HazePostEventFireForget(PlayPoofAudioEvent, FTransform(), AttachToComp = StarMesh);
	}

	void TriggerSupernova()
	{
		Niagara::SpawnSystemAtLocation(SupernovaEffect, StarRoot.WorldLocation);
		System::SetTimer(this, n"TriggerSupernovaCamShake", 0.9f, false);
		DisableStarBuddy();
		UHazeAkComponent::HazePostEventFireForget(PlayExplodeAudioEvent, FTransform(), AttachToComp = StarMesh);

		FName EventName = SlappingPlayer.IsMay() ? n"FoghornDBPlayRoomSpaceStationStarBuddyMay" : n"FoghornDBPlayRoomSpaceStationStarBuddyCody";
		VOBank.PlayFoghornVOBankEvent(EventName);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerSupernovaCamShake()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(SupernovaCamShake, 2.f);
			Player.PlayForceFeedback(SupernovaForceFeedback, false, false, n"Supernova", 2.f);
		}
	}

	void DisableStarBuddy()
	{
		DisableActor(nullptr);
	}
}