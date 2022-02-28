import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStoneComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.StaticsCurling;

event void FActivateStone(ACurlingStone Stone, AHazePlayerCharacter Player);
event void FActivateShootCamera(AHazePlayerCharacter Player, ACurlingStone InputStone);
event void FGameStateShootInplay();
event void FStoneHasFallen(ACurlingStone Stone);

class ACurlingStone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	
	UPROPERTY(DefaultComponent, Attach = SphereComp)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = SphereComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent ShuffleAkComp;

	UPROPERTY(Category = "Setup")
	TArray<ACurlingStone> OtherStones;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartGlideLoop;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EndGlideLoop;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StoneImpact;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PlayerImpact;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent FallImpact;

	AHazePlayerCharacter OwningPlayer;

	UPROPERTY(Category = "Capabilities")	
	UHazeCapabilitySheet StoneCapabilitySheet;

	FActivateStone EventActivateStone;
	FActivateShootCamera EventActivateShootCamera;
	FGameStateShootInplay EventGameStateShootInplay;
	FStoneHasFallen EventStoneHasFallen;

	UPROPERTY(Category = "Type")
	ECurlingPlayerTarget CurlingPlayerTarget;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem ImpactWithWallSystem;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem ImpactWithPuckSystem;

	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect HitRumble;

	UPROPERTY(Category = "Setup")
	AHazeActor EdgeLine;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.UpdateSettings.OptimalCount = 3;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;

	UPROPERTY(DefaultComponent)
	UHazeNetworkControlSideInitializeComponent NetControlInitializeComp;

	FVector PullPower;

	UCurlingPlayerComp PlayerComp;

	UCurlingStoneComponent StoneComp;

	AHazePlayerCharacter PlayerReference;

	FVector InitializedPosition;

	FVector FallDirection;
	FVector LastEdgeHitLocation;
	float DistanceFromLastHit;
	bool bOffEdge;

	float InitialImpulseSpeed;
	float DistanceFromOrigin;
	float ZStartingHeight;
	float ZOutOfGameHeight;
	float ZOutAmount = 100.f;
	
	float CurrentTimeSystemSpawn;
	float MaxTimeSystemSpawn = 0.2f;

	bool bIsPlayerAffecting;
	bool bCanPlayRumble;
	bool bHasPlayed;
	bool bIsActive;
	bool bFirstTimeFalling;
	bool bAudioFirstTimeFalling;
	bool bIsControlledByPlayer;
	bool bHaveFallen;

	bool bIsAboveZLevel;
	bool bHeightInitialized;
	bool bIsBlocking;

	int AllocatedPoints;

	UPROPERTY(Category = "Collision Priority")
	int Index;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bFirstTimeFalling = true;
		bAudioFirstTimeFalling = true;
		
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivate");
		
		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"InteractionCondition");
		InteractionComp.AddPlayerCondition(Game::May, n"GroundedCheckNeeded", Condition);
		InteractionComp.AddPlayerCondition(Game::Cody, n"GroundedCheckNeeded", Condition);
		
		AddCapabilitySheet(StoneCapabilitySheet);

		SetPlayerReference();

		Network::SetActorControlSide(this, Game::GetMay());
		
		MoveComp.Setup(SphereComp);
		MoveComp.UseCollisionSolver(n"CurlingCollisionSolver", n"DefaultCharacterRemoteCollisionSolver");

		StoneComp = UCurlingStoneComponent::Get(this);
		SetCurlingTags();

		if (HasControl())
			SetPlayerControlSide();
	}

	UFUNCTION()
	bool InteractionCondition(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		return Player.MovementComponent.IsGrounded();
	}

	UFUNCTION()
	void StoneZValues()
	{
		ZStartingHeight = ActorLocation.Z;
		ZOutOfGameHeight = ZStartingHeight - ZOutAmount;
		bHeightInitialized = true;
	}

	UFUNCTION()
	void SetInitializedPosition()
	{
		InitializedPosition = ActorLocation;
	}

	UFUNCTION()
	void SetCurlingTags()
	{
		if (CurlingPlayerTarget == ECurlingPlayerTarget::May)
			AddActorTag(CurlingTags::StoneMay);
		else 
			AddActorTag(CurlingTags::StoneCody);
	}

	UFUNCTION(NetFunction)
	void SetPlayerControlSide()
	{
		if (CurlingPlayerTarget == ECurlingPlayerTarget::Cody)
			SetControlSide(Game::GetCody());
		else
			SetControlSide(Game::GetMay());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ActorLocation.Z < ZOutOfGameHeight)
			bIsAboveZLevel = false;
		else
			bIsAboveZLevel = true;

		if (CurrentTimeSystemSpawn > 0.f)
			CurrentTimeSystemSpawn -= DeltaTime;
	}

	UFUNCTION()
	void ResetPositionAndState()
	{
		ActorLocation = InitializedPosition;
		MoveComp.ConsumeAccumulatedImpulse();
		MoveComp.Velocity = 0.f;
		bIsActive = false;
		bHaveFallen = false;
		bAudioFirstTimeFalling = true;
	}

	UFUNCTION()
	void InteractionActivate(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		PlayerComp = UCurlingPlayerComp::Get(Player);
		
		OwningPlayer = Player;

		if (PlayerComp == nullptr)
			return;
		
		PlayerComp.TargetStone = this;
		PlayerComp.PlayerCurlState = EPlayerCurlState::Engaging;
	}

	UFUNCTION(NetFunction)
	void BroadcastEventActivateStoneAndCamera(AHazePlayerCharacter Player)
	{
		EventActivateStone.Broadcast(this, Player);
		EventActivateShootCamera.Broadcast(Player, this);
		StoneComp.EventReleaseStone.Broadcast();
		EventGameStateShootInplay.Broadcast();
	}

	void SetPlayerReference()
	{
		if (CurlingPlayerTarget == ECurlingPlayerTarget::May)
			PlayerReference = Game::GetMay();
		else 
			PlayerReference = Game::GetCody();
	}

	UFUNCTION()
	void EnablePlayerInteraction()
	{
		InteractionComp.EnableAfterFullSyncPoint(n"Shootable");
	}

	UFUNCTION()
	void DisablePlayerInteraction()
	{
		InteractionComp.Disable(n"Shootable");
	}

	UFUNCTION()
	void DisableAllOtherPucks()
	{
		for (ACurlingStone Stone : OtherStones)
		{
			if (Stone.IsAnyCapabilityActive(CapabilityTags::Movement))
				Stone.BlockPuckMovement();
		}
	}

	UFUNCTION(NetFunction)
	void EnableAllOtherPucks()
	{
		for (ACurlingStone Stone : OtherStones)
		{
			if (!Stone.IsAnyCapabilityActive(CapabilityTags::Movement))
				Stone.EnablePuckMovement();
		}
	}

	UFUNCTION()
	void BlockPuckMovement()
	{
		if (!bIsBlocking)
		{
			bIsBlocking = true;
			BlockCapabilities(CapabilityTags::Movement, this);
		}
	}

	UFUNCTION()
	void EnablePuckMovement()
	{
		if (bIsBlocking)
		{
			bIsBlocking = false;
			UnblockCapabilities(CapabilityTags::Movement, this);
		}
	}

	void InitializeStone()
	{
		bHasPlayed = false;
		bIsActive = true;
	}

	void PlayRumble()
	{
		if (OwningPlayer == nullptr)
			return;
		
		if (bCanPlayRumble)
			OwningPlayer.PlayForceFeedback(HitRumble, false, true, n"PuckImpactRumble");
	}

	void SpawnImpactWithWallSystem(FVector Location, FRotator Rotation)
	{
		if (ImpactWithWallSystem == nullptr)
			return;

		if (CurrentTimeSystemSpawn > 0.f)
			return;

		Niagara::SpawnSystemAtLocation(ImpactWithWallSystem, Location, Rotation);
		CurrentTimeSystemSpawn = MaxTimeSystemSpawn;
	}

	void SpawnImpactWithPuckSystem(FVector Location, FRotator Rotation)
	{
		if (ImpactWithPuckSystem == nullptr)
			return;

		if (CurrentTimeSystemSpawn > 0.f)
			return;
		
		Niagara::SpawnSystemAtLocation(ImpactWithPuckSystem, Location, Rotation);
		CurrentTimeSystemSpawn = MaxTimeSystemSpawn;
	}
	
	void AudioStartGlideEvent()
	{
		if (!ShuffleAkComp.bIsEnabled)
			return;

		ShuffleAkComp.HazePostEvent(StartGlideLoop);
	}

	void AudioEndGlideEvent()
	{
		if (!ShuffleAkComp.bIsEnabled)
			return;

		ShuffleAkComp.HazePostEvent(EndGlideLoop);
	}

	void AudioUpdateGlideRTPC(float FinalAudioGlideValue)
	{
		if (!ShuffleAkComp.bIsEnabled)
			return;
		
		ShuffleAkComp.SetRTPCValue("Rtcp_World_SideContent_SnowGlobe_MiniGame_ShuffleBoard_Curlingstone_Velocity", FinalAudioGlideValue);
	}

	void AudioOnCollideEvent(float FinalAudioGlideValue)
	{
		if (!ShuffleAkComp.bIsEnabled)
			return;

		ShuffleAkComp.SetRTPCValue("Rtcp_World_SideContent_SnowGlobe_MiniGame_ShuffleBoard_Curlingstone_Impact_Intensity", FinalAudioGlideValue);
		ShuffleAkComp.HazePostEvent(StoneImpact);
	}	

	void AudioOnPlayerCollideEvent(float VelocityRTPC, AHazePlayerCharacter Player)
	{
		if (!ShuffleAkComp.bIsEnabled)
			return;

		if (Player == nullptr)
			return;

		Player.PlayerHazeAkComp.HazePostEvent(PlayerImpact);
		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_SnowGlobe_Town_ShuffleBoard_PlayerImpactStone", VelocityRTPC);
	}

	void AudioHitFloorEvent()
	{
		ShuffleAkComp.HazePostEvent(FallImpact);
	}

	FVector CollisionStrafeCheck(AHazePlayerCharacter Player, FVector DeltaMove, FVector& PlayerDirection)
	{
		FHazeTraceParams TraceParams;

		TraceParams.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
		TraceParams.SetToSphere(155.f);

		TraceParams.IgnoreActor(this);
		TraceParams.IgnoreActor(Player);
		
		TraceParams.From = Player.ActorLocation + Player.ActorForwardVector * PlayerComp.EngagedDistance + FVector(0.f, 0.f, 155.f);

		FHazeHitResult OutHit;
		TraceParams.To = Player.ActorLocation + DeltaMove + PlayerDirection * PlayerComp.EngagedDistance + FVector(0.f, 0.f, 155.f);

		if (TraceParams.Trace(OutHit))
		{
			Trace::PullbackHazeHitFromImpact(OutHit, 1.f);

			if (OutHit.bStartPenetrating)
			{
				// PlayerDirection = Player.ActorForwardVector;
				return OutHit.Normal * OutHit.PenetrationDepth;
			}

			FVector ToWall = DeltaMove * OutHit.Time;
			FVector Remainder = DeltaMove - ToWall;
			
			//Using normal of the plane to constrain
			FVector Redirected = Remainder.ConstrainToPlane(OutHit.Normal);

			// PlayerDirection = Player.ActorForwardVector;

			return Redirected;
		}

		return DeltaMove;
	}
}