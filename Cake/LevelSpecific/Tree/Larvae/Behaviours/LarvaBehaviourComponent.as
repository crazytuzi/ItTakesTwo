import Vino.Movement.Capabilities.KnockDown.CharacterKnockDownCapability;
import Cake.LevelSpecific.Tree.Larvae.LocomotionFeatureWaspLarva;
import Cake.LevelSpecific.Tree.Larvae.Settings.LarvaComposableSettings;
import Cake.Weapons.Sap.SapManager;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Tree.Larvae.Teams.LarvaTeam;
import Cake.Weapons.Sap.SapWeaponSettings;

enum ELarvaState
{
    None,
	Hatching,
    Idle,
    Pursue,
    Attack,
    Stunned,

	MAX
}

enum ELarvaPriority
{
	None,
	Low,
	Medium,
	High,
}

FName GetLarvaStateTag(ELarvaState State)
{
	switch (State)
	{
		case ELarvaState::None: return NAME_None;
		case ELarvaState::Hatching: return n"LarvaHatching";
		case ELarvaState::Idle: return n"LarvaIdle";
		case ELarvaState::Pursue: return n"LarvaPursue";
		case ELarvaState::Attack: return n"LarvaAttack";
		case ELarvaState::Stunned: return n"LarvaStunned";
	}
	return NAME_None;
}

event void FLarvaOnDie(AHazeActor Larva);
event void FLarvaHitBySap();
event void FLarvaHitByMatch();
event void FLarvaOnJustHatched(AHazeActor Larva);
event void FLarvaOnDisabled(AHazeActor Larva);
event void FLarvaOnCloseToTarget(AHazeActor Larva);

class ULarvaBehaviourComponent : UActorComponent
{
    // Todo: Would be better with an effects component 
    UPROPERTY(Category = "Effects")
    UNiagaraSystem ExplosionEffect = Asset("/Game/Effects/Gameplay/Tree/WaspLarva_Explode.WaspLarva_Explode");
    UPROPERTY(Category = "Effects")
    UNiagaraSystem FuseEffect = Asset("/Game/Effects/Gameplay/Wasps/WaspBlasterBoltShoot.WaspBlasterBoltShoot");
    UPROPERTY(Category = "Effects")
    UNiagaraSystem EatEffect = Asset("/Game/Effects/Gameplay/Sap/Sap_Splat_System.Sap_Splat_System");

	// Color by fraction of eaten sap needed to be explosive (0 at start, 1 when explosive)
    UPROPERTY(Category = "Effects")
	UCurveLinearColor EmissiveColorCurve; 

	UPROPERTY()
	ULocomotionFeatureWaspLarva AnimFeature = Asset("/Game/Blueprints/LevelSpecific/Tree/AI/WaspLarva/DA_WaspLarvaAnimFeature.DA_WaspLarvaAnimFeature");

    // The behaviour state we will begin in
    UPROPERTY(Category = "LarvaBehaviour|State")
    ELarvaState CurrentState = ELarvaState::None;
    ELarvaState StateLastUpdate = ELarvaState::None;
    ELarvaState PreviousState = ELarvaState::None;
    float StateChangeTime = 0.f;
	ELarvaPriority CurrentActivePriority = ELarvaPriority::None;

	UPROPERTY()
	ULarvaComposableSettings DefaultSettings = nullptr;
	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	ULarvaComposableSettings Settings;

    AHazeCharacter CharOwner = nullptr;
    AHazeActor CurrentTarget;
    UHazeAITeam Team;

    // Triggers when we die
	UPROPERTY(meta = (NotBlueprintCallable))
	FLarvaOnDie OnDie;

    // Triggers when we get hit by sap
	FLarvaHitBySap OnHitBySap;

    // Triggers when we get hit by a match
	UPROPERTY(meta = (NotBlueprintCallable))
	FLarvaHitByMatch OnHitByMatch;

	FLarvaOnJustHatched OnJustHatched;
	FLarvaOnCloseToTarget OnCloseToTarget;
	FLarvaOnDisabled OnDisabled;

    // We have this much sap attached to us
    float AttachedSap = 0.f;

	// We've eaten this much sap
	float EatenSap = 0.f;
	FHazeAcceleratedFloat SapInBelly;

	UAutoAimTargetComponent AutoAimTargetComp;

	// Do we have unattached sap to eat?
	ASapBatch EatableSap = nullptr;

	// Approximate world height the current target was last at when on ground.
	float TargetGroundHeight = BIG_NUMBER; 

	bool bIsDead = false;
	bool bReportedCloseToTarget = false;

	UPROPERTY()
	FRotator HatchRotation;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CharOwner = Cast<AHazeCharacter>(GetOwner());
        Team = CharOwner.JoinTeam(n"LarvaTeam", ULarvaTeam::StaticClass());

		// Make sure players have some common capabilities
		Team.AddPlayersCapability(UCharacterKnockDownCapability::StaticClass());

		// Set up default settings
		if (DefaultSettings != nullptr)
			CharOwner.ApplySettings(DefaultSettings, this, EHazeSettingsPriority::Defaults);
		Settings = ULarvaComposableSettings::GetSettings(CharOwner);
		
		HatchRotation = Owner.ActorRotation;

		AutoAimTargetComp = UAutoAimTargetComponent::Get(Owner);

        ensure((Team != nullptr) && (CharOwner != nullptr) && (AutoAimTargetComp != nullptr));

		Reset();
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasValidTarget())
		{
			UHazeBaseMovementComponent TargetMoveComp = UHazeBaseMovementComponent::Get(Target);
			if ((TargetMoveComp == nullptr) || (Target.ActorLocation.Z < TargetGroundHeight) || !TargetMoveComp.IsAirborne())
				TargetGroundHeight = Target.ActorLocation.Z;					
			
			if (!bReportedCloseToTarget && (State == ELarvaState::Pursue) && 
				(Owner.ActorLocation.IsNear(Target.ActorLocation, Settings.AttackDistance * 10.f)))
			{
				bReportedCloseToTarget = true;
				OnCloseToTarget.Broadcast(CharOwner);
			}
		}
		else
		{
			TargetGroundHeight = BIG_NUMBER;			
		}

		UpdateEatenSap(DeltaTime);
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        CharOwner.LeaveTeam(n"LarvaTeam");
    }

    void InitializeStates()
    {
        UpdateState();
    }

	ELarvaState GetState() const property
	{
		return CurrentState;
	}

	void SetState(ELarvaState NewState) property
	{
		CurrentState = NewState;
	}

    void UpdateState()
    {
        if (CurrentState != StateLastUpdate)
        {
            PreviousState = StateLastUpdate;
            StateLastUpdate = State;
            StateChangeTime = Time::GetGameTimeSeconds();
			CurrentActivePriority = ELarvaPriority::None;
        }
    }

    float GetStateDuration() property
    {
        return Time::GetGameTimeSince(StateChangeTime);
    }

    AHazeActor GetTarget() const property
    {
        return CurrentTarget;
    }

    void SetTarget(AHazeActor NewTarget) property
    {
        if (CurrentTarget == NewTarget)
            return;

        CurrentTarget = NewTarget;
		if (NewTarget != nullptr)
			TargetGroundHeight = NewTarget.ActorLocation.Z;
    }

	bool IsValidTarget(AHazeActor CheckTarget)
	{
		if (CheckTarget == nullptr)
			return false;
		if (CheckTarget.IsActorDisabled())
			return false;
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(CheckTarget);
		if ((PlayerTarget != nullptr) && IsPlayerDead(PlayerTarget))
			return false;
		return true;
	}

	bool HasValidTarget()
	{
		return IsValidTarget(CurrentTarget);
	}

	bool CanEatSap()
	{
		return (EatableSap != nullptr) || (AttachedSap > 0.f);
	}

    UFUNCTION()
    void OnSapAdded(FSapAttachTarget Where, float Mass)
    {
        AttachedSap += Mass;
		UpdateCustomSapBlob();
        OnHitBySap.Broadcast();
    }

    UFUNCTION()
    void OnSapRemoved(FSapAttachTarget Where, float Mass)
    {
        AttachedSap -= Mass;
		UpdateCustomSapBlob();
    }

    UFUNCTION()
    void OnSapExploded(FSapAttachTarget Where, float Mass)
    {
        Explode();
    }

    UFUNCTION()
    void OnSapExplodedProximity(FSapAttachTarget Where, float Mass, float Distance)
    {
		if (Distance < Settings.ExplodingSapDeathRadius)
        	Explode();
    }

	UFUNCTION()
    void Die()
    {
		bIsDead = true;

		if (!HasControl())
		{
			// Hide until confirmed dead. 
			// We don't want to send any network messages to handle this since there are a lot of larvae
			// and at worst we'll get an invisible larva exploding from attacking player right after being hidden by this.
			CharOwner.Mesh.SetHiddenInGame(true);
		}
    }

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		AttachedSap = 0.f;
		UpdateCustomSapBlob();
		EatenSap = 0.f;
		SapInBelly.SnapTo(0.f);
		SetTarget(nullptr);
		State = ELarvaState::None;
		CurrentActivePriority = ELarvaPriority::None;
		EatableSap = nullptr;
		bIsDead = false;
		bReportedCloseToTarget = false;
		CharOwner.Mesh.StopAllSlotAnimations(0.1f);
		if (EmissiveColorCurve != nullptr)
			CharOwner.Mesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", EmissiveColorCurve.GetLinearColorValue(0.f));
		else
			CharOwner.Mesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", FLinearColor::Black);
		AutoAimTargetComp.SetAutoAimEnabled(false);
		CharOwner.Mesh.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		if (State != ELarvaState::Hatching)
        	State = ELarvaState::None;

		DisableAllSapsAttachedTo(Owner.RootComponent);

		CharOwner.BlockMovementSyncronization(this);

		// Do not leave larva team until end play
        CharOwner.BlockCapabilities(n"Behaviour", this);

		OnDisabled.Broadcast(CharOwner);
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (State != ELarvaState::Hatching)
			State = ELarvaState::Idle;

        CharOwner.UnblockCapabilities(n"Behaviour", this);
		CharOwner.CleanupCurrentMovementTrail();
		CharOwner.UnblockMovementSyncronization(this);

		AutoAimTargetComp.SetAutoAimEnabled(false);

		System::SetTimer(this, n"PostEnabledDelay", 0.5f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void PostEnabledDelay()
	{
		if (bIsDead || CharOwner.IsActorDisabled())
			return;
		OnJustHatched.Broadcast(CharOwner);
	}

	UFUNCTION()
	void Explode()
	{
		UNiagaraComponent ExploEffect = Niagara::SpawnSystemAtLocation(ExplosionEffect, CharOwner.GetActorLocation());
		if ((Settings.EatenSapExplosiveAmount > 0.f) && (EmissiveColorCurve != nullptr))
		{
			float Alpha = FMath::Clamp(EatenSap / Settings.EatenSapExplosiveAmount, 0.f, 1.f);
			FLinearColor Color = EmissiveColorCurve.GetLinearColorValue(Alpha);
			ExploEffect.SetColorParameter(n"SapColor", Color);
		}

		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for (AHazePlayerCharacter Player : Players)
		{
			if (Player.GetActorLocation().DistSquared(CharOwner.GetActorLocation()) < FMath::Square(400.f))
				Player.SetCapabilityAttributeObject(n"WaspExplosion", CharOwner);	
		}

		Die();
	}

    UFUNCTION()
    void OnMatchImpact(AActor IgnitionSource, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
    {
		if (Settings.bExplodesFromMatch)
			Explode(); // We're flammable!
		else if (EatenSap >= Settings.EatenSapExplosiveAmount)
			Explode(); // We're gorged with sap
		else if (State == ELarvaState::Stunned)
			Explode(); // Eating
    }

	FVector GetEatLocation() property
	{
		return CharOwner.GetActorLocation() + CharOwner.GetActorTransform().TransformVector(FVector(150.f, 0.f, -60.f));
	}

	void EatSap(float Amount)
	{
		EatenSap += Amount;

		if (!AutoAimTargetComp.bIsAutoAimEnabled && (EatenSap >= Settings.EatenSapExplosiveAmount))
			AutoAimTargetComp.SetAutoAimEnabled(true);
	}

	void UpdateEatenSap(float DeltaTime)
	{
		if (FMath::IsNearlyEqual(SapInBelly.Value, EatenSap, 0.1f))
			return; // No need to set color parameter when there's little change

		SapInBelly.AccelerateTo(EatenSap, 3.f, DeltaTime);
		if ((Settings.EatenSapExplosiveAmount > 0.f) && (EmissiveColorCurve != nullptr))
		{
			float Alpha = FMath::Clamp(SapInBelly.Value / Settings.EatenSapExplosiveAmount, 0.f, 1.f);
			FLinearColor Color = EmissiveColorCurve.GetLinearColorValue(Alpha);
			CharOwner.Mesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", Color);
		}
	}

	void UpdateCustomSapBlob()
	{
		if (Sap::Batch::MaxMass == 0)
			return;

	 	CharOwner.Mesh.SetScalarParameterValueOnMaterialIndex(1, n"SapFraction", AttachedSap / Sap::Batch::MaxMass);
	}
}
