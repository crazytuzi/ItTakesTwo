import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudBoundsComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudSettings;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudRepulsor;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Vino.Movement.Components.MovementComponent;

event void FOnCheckTileUnderCloud();


class UFollowCloudDisable : UActorComponent
{
	UPROPERTY(Category = "Disabling")
	FHazeMinMax DisableRange = FHazeMinMax(5000.f, 50000.f);

	UPROPERTY(Category = "Disabling")
	float ViewRadius = 900.f;

	UPROPERTY(Category = "Disabling")
	float DontDisableWhileVisibleTime = 1.f;

	AFollowCloud CloudOwner;
	bool bIsAutoDisabled = false;

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// This component never disables
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!CloudOwner.IsActorDisabled() || bIsAutoDisabled)
		{
			const bool bShouldBeAutoDisabled = ShouldAutoDisable();
			if(bIsAutoDisabled != bShouldBeAutoDisabled)
			{
				bIsAutoDisabled = bShouldBeAutoDisabled;
				SetActorDisabledInternal(bIsAutoDisabled);
			}
		}
	}

	private bool ShouldAutoDisable()
	{		
		if(CloudOwner.bIsCrying)
			return false;
		else if(CloudOwner.bIsListeningToSong)
			return false;
		else if(CloudOwner.bIsAngry)
			return false;
		else if(CloudOwner.CloudMesh.WasRecentlyRendered(DontDisableWhileVisibleTime))
			return false;

		return true;
	}

	private void SetActorDisabledInternal(bool bStatus)
	{
		if(bStatus)
			CloudOwner.DisableActor(this);
		else
			CloudOwner.EnableActor(this);
	}
}

class AFollowCloudManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USphereComponent ActivationTrigger;
	default ActivationTrigger.SphereRadius = 10000.f;

	UPROPERTY(EditInstanceOnly)
	TArray<AFollowCloud> CloudsToManage;

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ActivationTrigger.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlap");
        ActivationTrigger.OnComponentEndOverlap.AddUFunction(this, n"EndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(OverlappingPlayers.Num() == 0)
		{
			for(auto Cloud : CloudsToManage)
			{
				Cloud.DisableActor(this);
			}
		}
	}

   	UFUNCTION(NotBlueprintCallable)
    private void BeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			OverlappingPlayers.Add(Player);
			if(HasActorBegunPlay())
			{
				if(OverlappingPlayers.Num() == 1)
				{
					for(auto Cloud : CloudsToManage)
					{
						Cloud.EnableActor(this);
					}
				}
			}
		}
    }

    UFUNCTION(NotBlueprintCallable)
    private void EndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			OverlappingPlayers.Remove(Player);
			if(OverlappingPlayers.Num() == 0)
			{
				for(auto Cloud : CloudsToManage)
				{
					Cloud.DisableActor(this);
				}
			}
		}
    }	
}

class AFollowCloud : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = CloudMesh)
	UCapsuleComponent CapsuleComponent;
	default CapsuleComponent.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = RootComp) 
	UHazeSkeletalMeshComponentBase CloudMesh;
	default CloudMesh.bUseDisabledTickOptimizations = true;
	default CloudMesh.DisabledVisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bDepenetrateOutOfOtherMovementComponents = false;
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCymbalImpactComponent CymbalImpactComp;
	default CymbalImpactComp.bPlayVFXOnHit = false;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USongReactionComponent SongReaction;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UNiagaraComponent RainParticleSystem;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UNiagaraComponent RainSplashParticleSystem;

	UPROPERTY(DefaultComponent)
	UFollowCloudBoundsComponent Bounds;
	UPROPERTY(DefaultComponent)
	UFollowCloudRepulsorComponent Repulsor;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UAutoAimTargetComponent AutoAimTarget;

	// Only May can affect cloud movement
	UPROPERTY(DefaultComponent)
	UHazeNetworkControlSideInitializeComponent ControlSideComponent;
	default ControlSideComponent.ControlSide = EHazePlayer::May;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisable;

	UPROPERTY(DefaultComponent)
	UFollowCloudDisable DisableExtension;

	UPROPERTY(DefaultComponent, Attach = CloudMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartRainAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopRainAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AngryAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CloudHitAudioEvent;

	UPROPERTY(Category = "VO Events")
	UAkAudioEvent CloudHitVOEvent;

	UPROPERTY(Category = "VO Events")
	UAkAudioEvent CloudStartCryingVOEvent;

	UPROPERTY(Category = "VO Events")
	UAkAudioEvent CloudAngryVOEvent;

	UPROPERTY()
	UAnimSequence Sad;
	UPROPERTY()
	UAnimSequence Happy;
	UPROPERTY()
	UAnimSequence Angry;
	UPROPERTY()
	UAnimSequence AngrySad;
	UPROPERTY()
	UAnimSequence HappySad;
	UPROPERTY()
	UAnimSequence Neutral;

	UPROPERTY()
	APaintablePlane CloudTile;
	UPROPERTY()
	AStaticMeshActor RespawnLocation;
	UPROPERTY()
	AActor OutOfBoundsActorReturnLocation;

	UPROPERTY()
	AActor ExtraIgnoreActorOne;
	UPROPERTY()
	AActor ExtraIgnoreActorTwo;

	UPROPERTY()
	UNiagaraSystem CymbalImpactEffect;
	FVector MoveDirection;
	FVector CloudStartLocation;
	UMaterialInstanceDynamic Material;

	UPROPERTY()
	float WaterRadius = 2000.f;
	UPROPERTY()
	bool ShouldLookAtPlayer;

	UFollowCloudSettings Settings;

	UPROPERTY()
	float CryTimerConst = 10.f;
	float CryTimer;
	float FollowSpeed;

	UPROPERTY()
	float TimeBeforeAllowAnimaion = 1;
	bool bAllowAnimationUpdate = false;
	bool bIsCrying = false;
	bool bIsListeningToSong = false;
	bool bIsAngry = false;
	int AnimNumberPlaying = 0;
	float AngryTimer = 6.5f;
	float AngryTimerTemp = 6.5f;

	UPROPERTY()
	bool bCSCry = false;

	FVector BumpDirection = FVector::ZeroVector;
	FVector BumpLocation = FVector::ZeroVector;

	float MainTraceDefaultLength = 6000.f;
	FVector CurrentImpactLocation;
	FVector LastImpactLocation;
	float LastTraceTime = 0;
	bool InitalHitPointLocationSet = false;
	bool SplashEffectTimerCanBeTriggerd = false;
	bool LerpAndDrawTexture = false;
	
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"FollowCloudBumpCapability");			
		AddCapability(n"FollowCloudLookAtPlayersCapability");			
		AddCapability(n"FollowCloudOutOfBoundsCapability");			
		AddCapability(n"FollowCloudSongReactionCapability");			
		AddCapability(n"FollowCloudAvoidanceCapability");			
		AddCapability(n"FollowCloudPushAwayPlayersCapability");
		AddCapability(n"FollowCloudMovementCapability");
		System::SetTimer(this, n"AllowAnimationUpdate", TimeBeforeAllowAnimaion, false);

		MoveComp.Setup(CapsuleComponent);
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalImpact");
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
		CloudStartLocation = GetActorLocation();
		CryTimer = CryTimerConst;
		Material = CloudMesh.CreateDynamicMaterialInstance(0);
		RainParticleSystem.Deactivate();
		RainParticleSystem.SetHiddenInGame(true);
		RainSplashParticleSystem.Deactivate();
		RainSplashParticleSystem.SetHiddenInGame(true);

		if (Bounds.BoundsCenter == nullptr) // Just in case a cloud hasn't run construction script
			Bounds.BoundsCenter = OutOfBoundsActorReturnLocation;

		Settings = UFollowCloudSettings::GetSettings(this);

		DisableExtension.CloudOwner = this;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CapsuleComponent.RelativeLocation = FVector(0,0,0);
		Bounds.BoundsCenter = OutOfBoundsActorReturnLocation;
	}
	
	UFUNCTION(NotBlueprintCallable)
	void CymbalImpact(FCymbalHitInfo HitInfo)
	{
		SetAnimBoolParam(n"CymbalImpact", true);
		StartCrying();
		Niagara::SpawnSystemAtLocation(CymbalImpactEffect, HitInfo.HitLocation, GetActorRotation());
		HazeAkComp.HazePostEvent(CloudHitAudioEvent);
		HazeAkComp.HazePostEvent(CloudHitVOEvent);
	}

	UFUNCTION()
    void PowerfulSongImpact(FPowerfulSongInfo Info)
    {
		SetAnimBoolParam(n"PowerfulSongImpact", true);
		BumpDirection = Info.Direction;
		BumpLocation = Info.ImpactLocation;
		bIsAngry = true;
		HazeAkComp.HazePostEvent(AngryAudioEvent);
		HazeAkComp.HazePostEvent(CloudHitAudioEvent);
		HazeAkComp.HazePostEvent(CloudHitVOEvent);
		HazeAkComp.HazePostEvent(CloudAngryVOEvent);
		AngryTimerTemp = AngryTimer;
    }

	UFUNCTION()
	void StartAffectedBySongOfLife(FSongOfLifeInfo Info)
	{
		bIsListeningToSong = true;
	}
	
	UFUNCTION()
	void StopAffectedBySongOfLife(FSongOfLifeInfo Info)
	{
		bIsListeningToSong = false;
	}

	UFUNCTION()
	void AllowAnimationUpdate()
	{
		bAllowAnimationUpdate = true;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bAllowAnimationUpdate)
		{
			if(bIsAngry == true)
			{
				AngryTimerTemp -= DeltaSeconds;
				if(AngryTimerTemp <= 0)
				{
					bIsAngry = false;
					AngryTimerTemp = AngryTimer;
				}
			}
			if(bIsAngry == true && bIsCrying)
			{
				if(AnimNumberPlaying != 1)
				{
					AnimNumberPlaying = 1;
					FHazeAnimationDelegate OnBlendedIn;
					FHazeAnimationDelegate OnBlendingOut;
					PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = AngrySad, bLoop = true, BlendType = EHazeBlendType::BlendType_Crossfade, BlendTime = 0.85f, PlayRate = 1.0f, StartTime = 0.f, bPauseAtEnd = false);
				}
			}
			else if(bIsListeningToSong && bIsCrying)
			{
				if(AnimNumberPlaying != 2)
				{
					AnimNumberPlaying = 2;
					FHazeAnimationDelegate OnBlendedIn;
					FHazeAnimationDelegate OnBlendingOut;
					PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = HappySad, bLoop = true, BlendType = EHazeBlendType::BlendType_Crossfade, BlendTime = 0.85f, PlayRate = 1.0f, StartTime = 0.f, bPauseAtEnd = false);
				}
			}
			else if(bIsAngry == true)
			{
				if(AnimNumberPlaying != 3)
				{
					AnimNumberPlaying = 3;
					FHazeAnimationDelegate OnBlendedIn;
					FHazeAnimationDelegate OnBlendingOut;
					PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Angry, bLoop = true, BlendType = EHazeBlendType::BlendType_Crossfade, BlendTime = 0.85f, PlayRate = 1.0f, StartTime = 0.f, bPauseAtEnd = false);
				}
			}
			else if(bIsCrying)
			{
				if(AnimNumberPlaying != 4)
				{
					AnimNumberPlaying = 4;
					FHazeAnimationDelegate OnBlendedIn;
					FHazeAnimationDelegate OnBlendingOut;
					PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Sad, bLoop = true, BlendType = EHazeBlendType::BlendType_Crossfade, BlendTime = 0.85f, PlayRate = 1.0f, StartTime = 0.f, bPauseAtEnd = false);
				}
			}
			else if(bIsListeningToSong)
			{
				if(AnimNumberPlaying != 5)
				{
					AnimNumberPlaying = 5;
					FHazeAnimationDelegate OnBlendedIn;
					FHazeAnimationDelegate OnBlendingOut;
					PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Happy, bLoop = true, BlendType = EHazeBlendType::BlendType_Crossfade, BlendTime = 0.85f, PlayRate = 1.0f, StartTime = 0.f, bPauseAtEnd = false);
				}
			}
			else if(bIsCrying == false && bIsListeningToSong == false && bIsAngry == false)
			{
				if(AnimNumberPlaying != 6)
				{
					AnimNumberPlaying = 6;
					FHazeAnimationDelegate OnBlendedIn;
					FHazeAnimationDelegate OnBlendingOut;
					PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = Neutral, bLoop = true, BlendType = EHazeBlendType::BlendType_Crossfade, BlendTime = 0.85f, PlayRate = 1.0f, StartTime = 0.f, bPauseAtEnd = false);
				}
			}
		}

		if(bIsCrying == true)
		{
			if(Time::GetGameTimeSince(LastTraceTime) > 0.5f)
				UpdateGroundTrace();

			CurrentImpactLocation = FMath::Lerp(CurrentImpactLocation, LastImpactLocation, DeltaSeconds);
			RainSplashParticleSystem.SetWorldLocation(CurrentImpactLocation);

			if(!LerpAndDrawTexture)
				return;

			CryTimer -= DeltaSeconds;
			if(CryTimer > 0)
			{
				if(!bCSCry)
					CloudTile.LerpAndDrawTexture(CurrentImpactLocation, WaterRadius, FLinearColor(1, 0, 0, 1), FLinearColor(1, 0, 0, 1), true);
				else
				{
					CloudTile.LerpAndDrawTexture(GetActorLocation(), 2000, FLinearColor(1.f, 0.f, 0.f, 0.f),  FLinearColor(5.0f, 0.f, 0.f, 0.f) * DeltaSeconds, true, nullptr, true, FLinearColor(1.45f,1.45f,1.45f));
				}
			}

			if(CryTimer <= 0)
			{
				StopCrying();
			}
		}
	}

	void UpdateGroundTrace()
	{
		LastTraceTime = Time::GetGameTimeSeconds();
		FVector Start = GetActorLocation();
		
		FVector End = Start + -GetActorUpVector() * MainTraceDefaultLength;
		FQuat Rot = FVector(End - Start).ToOrientationQuat();
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.AddUnique(Game::GetCody());
		ActorsToIgnore.AddUnique(Game::GetMay());
		ActorsToIgnore.AddUnique(ExtraIgnoreActorOne);
		ActorsToIgnore.AddUnique(ExtraIgnoreActorTwo);
		ActorsToIgnore.AddUnique(this);
		TArray<FHitResult> HitResult;
		LastImpactLocation = End;
		//Trace::(Start, End, 30.f, ETraceTypeQuery::Camera, false, ActorsToIgnore, HitResult, -1.f);
		System::SphereTraceMultiByProfile(Start, End, 30.f, n"PlayerCharacter", false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);

		for (FHitResult Hit : HitResult)
		{	
			if(Hit.bBlockingHit)
			{	
				LastImpactLocation = Hit.ImpactPoint;
				if(InitalHitPointLocationSet == false)
				{
					InitalHitPointLocationSet = true;
					CurrentImpactLocation = LastImpactLocation;
				}
			}	
		}	
	}

	UFUNCTION()
	void StartCrying()
	{
		CryTimer = CryTimerConst;
		bIsCrying = true;
		UpdateGroundTrace();
		RainParticleSystem.SetHiddenInGame(false);
		RainParticleSystem.Activate();
		HazeAkComp.HazePostEvent(StartRainAudioEvent);
		HazeAkComp.HazePostEvent(CloudStartCryingVOEvent);

		if(SplashEffectTimerCanBeTriggerd == false)
		{
			SplashEffectTimerCanBeTriggerd = true;
			System::SetTimer(this, n"DelayStartSplashEffect", 0.9, false);
		}
	}
	UFUNCTION()
	void DelayStartSplashEffect()
	{
		SplashEffectTimerCanBeTriggerd = false;
		LerpAndDrawTexture = true;
		RainSplashParticleSystem.SetHiddenInGame(false);
		RainSplashParticleSystem.Activate();
	}


	UFUNCTION()
	void StopCrying()
	{
		CryTimer = CryTimerConst;
		InitalHitPointLocationSet = false;
		bCSCry = false;
		bIsCrying = false;
		LerpAndDrawTexture = false;
		LastImpactLocation = GetActorLocation();
		RainParticleSystem.Deactivate();
		RainParticleSystem.SetHiddenInGame(true);
		RainSplashParticleSystem.Deactivate();
		RainSplashParticleSystem.SetHiddenInGame(true);
		HazeAkComp.HazePostEvent(StopRainAudioEvent);
	}
}