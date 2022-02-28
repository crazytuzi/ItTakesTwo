import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

import Cake.LevelSpecific.Music.MusicTargetingComponent;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Grinding.UserGrindComponent;

#if !RELEASE
const FConsoleVariable CVar_DebugDrawSongOfLifeRange("SongOfLife.Range", 0);
#endif // RELEASE

enum ESongOfLifeAnimationState
{
	Full,
	FaceOnly,
	None
}

class USongOfLifeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SongOfLife");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	TArray<USongOfLifeComponent> Affected;

	TArray<USongOfLifeComponent> TempReactions;

	AHazePlayerCharacter Player;
	USingingComponent SingingComp;
	USongOfLifeContainerComponent SongOfLifeContainer;
	UHazeCrumbComponent CrumbComp;
	UMusicTargetingComponent TargetingComp;
	ULedgeGrabComponent LedgeGrabComp;
	UCharacterWallSlideComponent WallSlideComp;
	UUserGrindComponent GrindComp;

	USingingSettings SingingSettings;

	FSongOfLifeInfo CachedSongOfLifeInfo;

	float SongOfLifeRechargeRateCurrent = 0.0f;
	float SongOfLifeDepletedElapsed = 0.0f;

	float LastSongOfLifeMaximum = 0.0f;

	float SongOfLifeEffectDuration = 8.0f;

	float TargetEffectRadius = 0.0f;
	float EffectRadiusInputModifier = 0.0f;

	FHazeAcceleratedFloat AcceleratedTargetRadius;

	bool bDeactivateEffect = false;

	float VortexVelocityDuration = 2.0f;

	bool bCouldPlayAnimation = false;
	bool bWasDead = false;

	ESongOfLifeAnimationState AnimationState = ESongOfLifeAnimationState::Full;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		CachedSongOfLifeInfo.Instigator = Player;
		SingingComp = USingingComponent::GetOrCreate(Owner);
		SongOfLifeContainer = USongOfLifeContainerComponent::GetOrCreate(Owner);
		TargetingComp = UMusicTargetingComponent::Get(Owner);
		SingingSettings = USingingSettings::GetSettings(Owner);
		LedgeGrabComp = ULedgeGrabComponent::Get(Owner);
		WallSlideComp = UCharacterWallSlideComponent::Get(Owner);
		GrindComp = UUserGrindComponent::Get(Owner);

		LastSongOfLifeMaximum = SingingComp.SongOfLifeCurrent = SingingSettings.SongOfLifeDurationMaximum;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(SingingComp.SongOfLifeCurrent <= 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if (SingingComp.bChargingPowerfulSong)
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::SongOfLife))
			return EHazeNetworkActivation::DontActivate;

		if(SingingComp.SongofLifeCooldownCurrent > 0.0f)
			return EHazeNetworkActivation::DontActivate;

		if(TargetingComp.bIsTargeting)
			return EHazeNetworkActivation::DontActivate;

		if(SingingComp.SongOfLifeState == ESongOfLifeState::Depleted)
			return EHazeNetworkActivation::DontActivate;

		if(SingingComp.SongOfLifeState == ESongOfLifeState::Recharge)
		{
			if(SingingComp.SongOfLifeChargeAsFraction < SingingSettings.RequiredRechargeFractionAfterDepletion)
				return EHazeNetworkActivation::DontActivate;
		}
        
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SingingComp.bChargingPowerfulSong)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			
		if(SingingComp.SongOfLifeCurrent <= 0.0f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::SongOfLife))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(TargetingComp.bIsTargeting)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if(SingingComp.SongOfLifeState == ESongOfLifeState::Depleted)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AnimationState = ESongOfLifeAnimationState::None;
		bDeactivateEffect = false;
		TargetEffectRadius = SingingComp.EffectRadiusDefault;
		EffectRadiusInputModifier = 0.0f;
		SingingComp.ActivateSongOfLife();
		SongOfLifeRechargeRateCurrent = SingingSettings.SongOfLifeRechargeRate;
		SingingComp.SongOfLifeRechargeCooldownCurrent = SingingSettings.SongOfLifeRechargeCooldown;
		SingingComp.SongOfLifeState = ESongOfLifeState::Singing;
		UpdateSongOfLifeAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SingingComp.SongofLifeCooldownCurrent = SingingSettings.SongOfLifeCooldown;
		bDeactivateEffect = true;
		TargetEffectRadius = 0.0f;
		EffectRadiusInputModifier = 0.0f;
		SingingComp.DeactivateSongOfLife();
		Player.ClearIdealDistanceByInstigator(this, 1.f);

		if(HasControl())
		{
			for(int Index = Affected.Num() - 1; Index >= 0; --Index)
			{
				USongOfLifeComponent AffectedSongOfLife = Affected[Index];
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"SongComp", AffectedSongOfLife);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SongOfLifeEnd"), CrumbParams);
			}

			Affected.Reset();
		}

		if(FMath::IsNearlyZero(SingingComp.SongOfLifeCurrent))
		{
			SingingComp.SongOfLifeState = ESongOfLifeState::Depleted;
			SingingComp.OnSongOfLifeDepleted();
			SongOfLifeDepletedElapsed = SingingSettings.SongOfLifeDepletedCooldown;
		}
		else
		{
			SingingComp.SongOfLifeState = ESongOfLifeState::Cooldown;
		}

		VortexVelocityDuration =  SingingComp.VortexVelocityAppearAccelerationTime;

		StopSongOfLifeAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
#if TEST
		if(!SingingComp.bInfiniteSongOfLife)
#endif // TEST
			SingingComp.SongOfLifeCurrent = FMath::Max(SingingComp.SongOfLifeCurrent - DeltaTime, 0.0f);
		
		EffectRadiusInputModifier = SingingComp.InputRadiusModifier * FMath::GetMappedRangeValueClamped(FVector2D(0.0f, 1.0f), FVector2D(1.0f, 0.0f), GetAttributeValue(ActionNames::PowerfulSongCharge));

		if(HasControl())
		{
			TempReactions.Reset();

			for(USongOfLifeComponent SongComp : SongOfLifeContainer.SongOfLifeCollection)
			{
				if(SongComp.bSongOfLifeInRange && !Affected.Contains(SongComp))
				{
					TempReactions.Add(SongComp);
				}
			}

			for(USongOfLifeComponent SongComp : TempReactions)
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"SongComp", SongComp);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SongOfLifeBegin"), CrumbParams);
			}

			TempReactions.Reset();

			for(USongOfLifeComponent SongComp : SongOfLifeContainer.SongOfLifeCollection)
			{
				if(!SongComp.bSongOfLifeInRange && Affected.Contains(SongComp))
				{
					TempReactions.Add(SongComp);
				}
			}

			for(int Index = TempReactions.Num() - 1; Index >= 0; --Index)
			{
				USongOfLifeComponent SongComp = TempReactions[Index];
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"SongComp", SongComp);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SongOfLifeEnd"), CrumbParams);
			}
		}

		for(USongOfLifeComponent SongComp : Affected)
		{
			ASongOfLifeVFX VFXActor = SingingComp.AddOrGetVFX(SongComp);
			SingingComp.BP_OnSongOfLifeUpdate(DeltaTime, SongComp, VFXActor.NiagaraComp);
		}

		UpdateSongOfLifeAnimation();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		SingingComp.SongofLifeCooldownCurrent -= DeltaTime;
		const float TargetEffectRadiusTotal = TargetEffectRadius - EffectRadiusInputModifier;
		AcceleratedTargetRadius.SpringTo(TargetEffectRadiusTotal, SingingComp.SpringStiffness, SingingComp.SpringDamping, DeltaTime);

		float TargetRadiusFraction = FMath::IsNearlyZero(TargetEffectRadiusTotal) ? 0.0f : AcceleratedTargetRadius.Value / TargetEffectRadiusTotal;
		TargetRadiusFraction = FMath::GetMappedRangeValueClamped(FVector2D(0.0f, 1.0f), FVector2D(1.0f, 0.0f), TargetRadiusFraction);
		
		if(AcceleratedTargetRadius.Value < 40.0f && bDeactivateEffect)
		{
			SingingComp.DeactivateParticleEffect();
			bDeactivateEffect = false;
		}
		
		// Did we change settings from last frame?
		if(!FMath::IsNearlyEqual(LastSongOfLifeMaximum, SingingSettings.SongOfLifeDurationMaximum))
		{
			SingingComp.SongOfLifeCurrent = SingingSettings.SongOfLifeDurationMaximum;
		}
		
		if(SingingComp.SongOfLifeState == ESongOfLifeState::Cooldown)
		{
			SingingComp.SongOfLifeRechargeCooldownCurrent -= DeltaTime;
			if(SingingComp.SongOfLifeRechargeCooldownCurrent <= 0.0f)
			{
				SingingComp.SongOfLifeState = ESongOfLifeState::Recharge;
				SingingComp.OnSongOfLifeRechargeStart();
			}
		}
		else if(SingingComp.SongOfLifeState == ESongOfLifeState::Recharge)
		{
			SingingComp.SongOfLifeCurrent += SongOfLifeRechargeRateCurrent * DeltaTime;
			SongOfLifeRechargeRateCurrent += SingingSettings.SongOfLifeRechargeRateIncrement * DeltaTime;

			if(SingingComp.SongOfLifeCurrent >= SingingSettings.SongOfLifeDurationMaximum)
			{
				SingingComp.SongOfLifeCurrent = SingingSettings.SongOfLifeDurationMaximum;
				SingingComp.SongOfLifeState = ESongOfLifeState::None;
			}
		}
		else if(SingingComp.SongOfLifeState == ESongOfLifeState::Depleted)
		{
			SongOfLifeDepletedElapsed -= DeltaTime;
			
			if(SongOfLifeDepletedElapsed <= 0.0f)
			{
				SingingComp.SongOfLifeState = ESongOfLifeState::Recharge;
				SingingComp.OnSongOfLifeRechargeStart();
			}
		}

		UpdateWidgetProgress();

		LastSongOfLifeMaximum = SingingSettings.SongOfLifeDurationMaximum;

		const bool bIsDead = Player.IsPlayerDead();

		if(bWasDead && !bIsDead)
		{
			SingingComp.SongOfLifeCurrent = SingingSettings.SongOfLifeDurationMaximum;
			SingingComp.SongOfLifeState = ESongOfLifeState::None;
		}

		bWasDead = bIsDead;
	}

	float GetSongOfLifeProgress() const property
	{
		return FMath::Clamp(SingingComp.SongOfLifeCurrent / SingingSettings.SongOfLifeDurationMaximum, 0.0f, 1.0f);
	}

	UFUNCTION()
	private void Crumb_SongOfLifeBegin(FHazeDelegateCrumbData CrumbData)
	{
		USongOfLifeComponent SongComp = Cast<USongOfLifeComponent>(CrumbData.GetObject(n"SongComp"));
		if(!devEnsure(SongComp != nullptr))
			return;
		
		SongComp.StartAffectedBySongOfLife(CachedSongOfLifeInfo);
		SingingComp.OnSongOfLifeAppear(SongComp);
		Affected.AddUnique(SongComp);
	}

	UFUNCTION()
	private void Crumb_SongOfLifeEnd(FHazeDelegateCrumbData CrumbData)
	{
		USongOfLifeComponent SongComp = Cast<USongOfLifeComponent>(CrumbData.GetObject(n"SongComp"));
		if(!devEnsure(SongComp != nullptr))
			return;
		
		SongComp.StopAffectedBySongOfLife(CachedSongOfLifeInfo);
		SingingComp.OnSongOfLifeDisappear(SongComp);
		Affected.Remove(SongComp);
	}

	private void UpdateWidgetProgress()
	{
		SingingComp.UpdateWidgetProgress(SongOfLifeProgress);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		SingingComp.ClearVFXCollection();
	}

	void StartSongOfLifeAnimation()
	{
		if(SingingComp.SongOfLifeAnim == nullptr)
			return;

		if(SingingComp.SongOfLifeAnim != nullptr)
		{
			FHazePlayOverrideAnimationParams Params;
			Params.Animation = SingingComp.SongOfLifeAnim;
			Params.BoneFilter = GetBoneFilter();
			Params.BlendTime = 0.3f;
			Params.bLoop = true;

			Player.PlayOverrideAnimation(FHazeAnimationDelegate(), Params);
		}
	}

	EHazeBoneFilterTemplate GetBoneFilter() const
	{
		if(AnimationState == ESongOfLifeAnimationState::FaceOnly)
			return EHazeBoneFilterTemplate::BoneFilter_Face;
		return EHazeBoneFilterTemplate::BoneFilter_Spine;
	}

	void StopSongOfLifeAnimation()
	{
		if(SingingComp.SongOfLifeAnim != nullptr)
		{
			Player.StopOverrideAnimation(SingingComp.SongOfLifeAnim);
		}
	}

	ESongOfLifeAnimationState GetWantedSongOfLifeAnimationState() const
	{
		const bool bIsLedgeGrabbing = LedgeGrabComp.CurrentState != ELedgeGrabStates::None;
		const bool bIsWallSliding = WallSlideComp.bSlidingIsActive;
		const bool bIsGrinding = GrindComp.HasActiveGrindSpline();
		
		if(bIsLedgeGrabbing 
		|| bIsWallSliding
		|| bIsGrinding)
		{
			return ESongOfLifeAnimationState::FaceOnly;
		}

		return ESongOfLifeAnimationState::Full;
	}

	void UpdateSongOfLifeAnimation()
	{
		ESongOfLifeAnimationState WantedState = GetWantedSongOfLifeAnimationState();

		if(WantedState != AnimationState)
		{
			AnimationState = WantedState;
			StartSongOfLifeAnimation();
		}
	}
}
