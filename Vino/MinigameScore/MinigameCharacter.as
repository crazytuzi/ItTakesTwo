import Vino.MinigameScore.MinigameStatics;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.Weapons.Hammer.HammerableComponent;
import Vino.Pierceables.PierceableComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.Weapons.Match.MatchHitResponseComponent;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Vino.BouncePad.BouncePadResponseComponent;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.Weapons.Sap.SapManager;

event void FOnAnnouncementCompleted();
event void FOnAnnouncementStarted(AHazePlayerCharacter DiscoveryPlayer);
event void FOnBounceTambourineBouncedOn(AHazePlayerCharacter Player);
event void FOnTambourineImpact(FVector HitFromLocation, float Impulse);

UCLASS(Abstract)
class AMinigameCharacter : AHazeActor
{
	
//*** MAIN SETUP ***//
	FOnAnnouncementCompleted OnAnnouncementCompletedEvent;
	
	FOnAnnouncementStarted OnAnnouncementStarted;

	FOnTambourineImpact OnTambourineImpact;

	UPROPERTY(DefaultComponent, RootComponent)	
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;
	default SkeletalMesh.ReceivesDecals = false;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SmokeSparkleSystem;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh)
	UNiagaraComponent ConstantSparkleSystem;

//*** TAMBOURINE REACTIONS ***//
	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY(DefaultComponent)
	UBouncePadResponseComponent BouncePadComp;

    UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1500.f;

    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;

    UPROPERTY(EditDefaultsOnly, Category = "Bounce Properties")
    TSubclassOf<UHazeCapability> BouncePadCapabilityClass;
	// default BouncePadCapabilityClass = Asset("/Game/Blueprints/LevelMechanics/YBP_CharacterBouncePad.YBP_CharacterBouncePad_C");

	UPROPERTY(EditDefaultsOnly, Category = "Bounce Properties")
	UNiagaraSystem BounceEffect = Asset("/Game/Effects/Niagara/GameplayBouncePad_01.GameplayBouncePad_01");

    UPROPERTY()
    FOnBounceTambourineBouncedOn OnBouncePadBouncedOn;

//*** GENERAL SETUP AND REFERENCES***//
 	TPerPlayer<AHazePlayerCharacter> Players;

	FHazeAcceleratedRotator AcceleratedRotator;

	UPROPERTY()
	EMinigameCharacterState TambourineState;

	UActorComponent MinigameCompRef;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent TambHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PoofAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpawnAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BounceAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLoopAudioEvent;

	bool bIsPLayingLoop = false;
	
	float CurrentZTarget;

	const float ZOffsetUp = 1.5f;
	const float ZOffsetDown = -1.5f;
	float NewZ;
	float MinDiscoveryDistance = 2100.f;

	UPROPERTY()
	int HitCount;

	int MaxHitCountReaction = 3;

	const float ImpulseNail = 65.f;
	const float ImpulseHammer = 70.f;
	const float ImpulseMatchStick = 60.f;
	const float ImpulseExplosion = 120.f;
	const float ImpulseVinewhip = 70.f;
	const float ImpulseSnowballHit = 50.f;
	const float ImpulseSong = 60.f;
	const float ImpulseCymbal = 65.f;

	bool bCanMoveUp;
	bool bTambDisappear;

	UPROPERTY()
	bool bGameDiscovered;

	UPROPERTY()
	bool bLoopingReaction;

	UPROPERTY(Category = "Mesh")
	bool bSpecificImpactComponent = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Players[0] = Game::May;
			Players[1] = Game::Cody;

		AcceleratedRotator.SnapTo(ActorRotation);
		CurrentZTarget = ZOffsetUp;

        FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnBouncePad");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);

		if (SmokeSparkleSystem != nullptr)
			SmokeSparkleSystem.Deactivate();

		System::SetTimer(this, n"DelayedActivateSystem", 0.5f, false);

		if (!BouncePadCapabilityClass.IsValid())
		{
			// Megahack to workaround BP inheritance issue I have no energy to debug
			BouncePadCapabilityClass = Cast<UClass>(FindObject(nullptr, "/Game/Blueprints/LevelMechanics/YBP_CharacterBouncePad.YBP_CharacterBouncePad_C"));
			devEnsure(BouncePadCapabilityClass.IsValid(), "The megahack didn't work....");
		}

        Capability::AddPlayerCapabilityRequest(BouncePadCapabilityClass);

		TambHazeAkComp.SetTrackElevation(true, 1000.f);
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        Capability::RemovePlayerCapabilityRequest(BouncePadCapabilityClass);
    }

	UFUNCTION()
	void DelayedActivateSystem()
	{
		if (SmokeSparkleSystem != nullptr)
			SmokeSparkleSystem.Activate();
	}

	void AngryReactionCheck()
	{
		HitCount++;

		if (HitCount >= MaxHitCountReaction)
		{
			HitCount = 0;
			SetAnimBoolParam(n"AnimParam_AngryReaction", true);
		}
	}

	UFUNCTION()
	void SnowBallHit(AActor ProjectileOwner, FHitResult Hit, FVector HitVelocity)
	{
		OnTambourineImpact.Broadcast(ProjectileOwner.ActorLocation, ImpulseSnowballHit);
		SetAnimBoolParam(n"AnimParam_SmallHit", true);
		AngryReactionCheck();
	}

	UFUNCTION()
	void HammerHit(AActor ActorDoingTheHammering, AActor ActorBeingHammered, FComponentsBeingHammered ComponentsBeing)
	{
		OnTambourineImpact.Broadcast(Game::May.ActorLocation, ImpulseHammer);
		SetAnimBoolParam(n"AnimParam_TopHit", true);
		AngryReactionCheck();
	}

	UFUNCTION()
	void OnPierced(AActor ActorDoingThePiercing, AActor ActorBeingPierced, UPrimitiveComponent CompBeingPiercead, FHitResult HitResult)
	{
		OnTambourineImpact.Broadcast(Game::Cody.ActorLocation, ImpulseNail);
		SetAnimBoolParam(n"AnimParam_SmallHit", true);
		AngryReactionCheck();
	}

	UFUNCTION()
	void SapExploded(FSapAttachTarget Where, float Mass)
	{
		OnTambourineImpact.Broadcast(Game::May.ActorLocation, ImpulseExplosion);
		SetAnimBoolParam(n"AnimParam_SmallHit", true);
		AngryReactionCheck();
	}

	UFUNCTION()
	void MatchStickyHit(AActor Match, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
	{
		OnTambourineImpact.Broadcast(Game::May.ActorLocation, ImpulseMatchStick);
		SetAnimBoolParam(n"AnimParam_ExplosionHit", true);
		AngryReactionCheck();
	}

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		OnTambourineImpact.Broadcast(Game::Cody.ActorLocation, ImpulseCymbal);
		SetAnimBoolParam(n"AnimParam_SmallHit", true);
		AngryReactionCheck();
	}

	UFUNCTION()
	void PowerfulSongImpact(FPowerfulSongInfo Info)
	{
		OnTambourineImpact.Broadcast(Game::May.ActorLocation, ImpulseSong);
		SetAnimBoolParam(n"AnimParam_SmallHit", true);
		AngryReactionCheck();
	}

	UFUNCTION()
	void WaterHoseHit()
	{
		bLoopingReaction = true;
		
		if (!bIsPLayingLoop)
		{
			TambHazeAkComp.HazePostEvent(StartLoopAudioEvent);
			bIsPLayingLoop = true;
		}
	}

	UFUNCTION()
	void VineWhip()
	{
		OnTambourineImpact.Broadcast(Game::Cody.ActorLocation, 70.f);
		SetAnimBoolParam(n"AnimParam_SmallHit", true);
		AngryReactionCheck();
	}

    UFUNCTION()
    void PlayerLandedOnBouncePad(AHazePlayerCharacter Player, FHitResult HitResult)
    {
		bool bGroundPounded = false;
		Player.PlayerHazeAkComp.HazePostEvent(BounceAudioEvent);
		
		if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
		{
			bGroundPounded = true;
		}
			
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
		
		if (Player.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
			SetAnimBoolParam(n"AnimParam_GroundPound", true);
		else
			SetAnimBoolParam(n"AnimParam_TopHit", true);

		if (BounceEffect != nullptr)
			Niagara::SpawnSystemAtLocation(BounceEffect, Player.ActorLocation);
    }

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnBounceHit(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"PlayerReference"));

		bool bGroundPounded = false;
		
		if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
		{
			bGroundPounded = true;
		}
			
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
		
		if (Player.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
			SetAnimBoolParam(n"AnimParam_GroundPound", true);
		else
			SetAnimBoolParam(n"AnimParam_TopHit", true);
	}

	UFUNCTION()
	void SmallHitReaction()
	{
		SetAnimBoolParam(n"AnimParam_SmallHit", true);
	}

	UFUNCTION()
	void BigHitReaction()
	{
		SetAnimBoolParam(n"AnimParam_ExplosionHit", true);
	}

	UFUNCTION()
	void LoopingReactionEnd()
	{
		bLoopingReaction = false;
		TambHazeAkComp.HazePostEvent(StopLoopAudioEvent);
		bIsPLayingLoop = false;
		AngryReactionCheck();
	}

	void SetCharacterReactionMinDistance(float InputMinDistance, UActorComponent InputMinigameCompRef)
	{
		MinigameCompRef = InputMinigameCompRef;
		MinDiscoveryDistance = InputMinDistance;
	}

	UFUNCTION()
	void OnTambDespawned()
	{
		DisableAllSapsAttachedTo(RootComponent);
	}
}