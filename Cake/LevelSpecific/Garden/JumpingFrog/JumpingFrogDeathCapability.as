import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Vino.Movement.Components.MovementComponent;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Foghorn.FoghornStatics;

enum EJumpingFrogDeathType
{
	None,
	Water,
	Piercable,
	Slime
}

class UJumpingFrogDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	AJumpingFrog OwningFrog;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	EJumpingFrogDeathType RespawnType = EJumpingFrogDeathType::None;

	FVector RespawnLocation;
	FVector RespawnFwdDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningFrog = Cast<AJumpingFrog>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{	
		if(!IsBlocked() && !IsActive() && HasControl())
		{
			RespawnType = EJumpingFrogDeathType::None;
			if(!CheckHitDeathTag(MoveComp.DownHit, RespawnType))
				if(!CheckHitDeathTag(MoveComp.ForwardHit, RespawnType))
					CheckHitDeathTag(MoveComp.UpHit, RespawnType);
		}
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(n"ForceDeath"))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if(RespawnType == EJumpingFrogDeathType::None)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(OwningFrog.bDying)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		if((IsActioning(n"ForceDeath")))
		{
			Params.AddNumber(n"DeathType", int(2));
			OwningFrog.SetCapabilityActionState(n"ForceDeath", EHazeActionState::Inactive);
		}
		else
			Params.AddNumber(n"DeathType", int(RespawnType));
		
		Params.AddVector(n"RespawnLocation", OwningFrog.RespawnTransform.Location);
		Params.AddVector(n"RespawnFwdDirection", OwningFrog.RespawnTransform.Rotation.GetForwardVector());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RespawnType = EJumpingFrogDeathType(ActivationParams.GetNumber(n"DeathType"));


		PauseFoghornActor(OwningFrog);
		
		if(OwningFrog.MountedPlayer != nullptr)
			PauseFoghornActor(OwningFrog.MountedPlayer);

		OwningFrog.DeathCount++;

		// The death effect will reset this bool when its done
		OwningFrog.bDying = true;
		auto PlayerHealth = UPlayerHealthComponent::Get(OwningFrog.MountedPlayer);

		TSubclassOf<UPlayerDeathEffect> DeathEffect;
		if(RespawnType == EJumpingFrogDeathType::Water)
			DeathEffect = OwningFrog.WaterDeathEffect;
		else if(RespawnType == EJumpingFrogDeathType::Piercable)
			DeathEffect = OwningFrog.PiercedDeathEffect;
		else if(RespawnType == EJumpingFrogDeathType::Slime)
			DeathEffect = OwningFrog.SlimeDeathEffect;
	
		if (!DeathEffect.IsValid())
			DeathEffect = PlayerHealth.GetDefaultEffect_Death();

		OwningFrog.SetCapabilityActionState(n"AudioFrogDeath", EHazeActionState::ActiveForOneFrame);
		RespawnLocation = ActivationParams.GetVector(n"RespawnLocation");
		RespawnFwdDirection = ActivationParams.GetVector(n"RespawnFwdDirection");
	
		if (PlayerHealth.HasControl() && !PlayerHealth.bIsDead)
			PlayerHealth.LeaveDeathCrumb(TSubclassOf<UPlayerDeathEffect>(UDummyPlayerDeathEffect::StaticClass()));
		PlayerHealth.PlayDeathEffect(DeathEffect, ActivationParams.IsStale());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		OwningFrog.bDying = false;

		ResumeFoghornActor(OwningFrog);

		if(OwningFrog.MountedPlayer != nullptr)
			ResumeFoghornActor(OwningFrog.MountedPlayer);

		if(OwningFrog.DeathCount == 3)
		{
			if(OwningFrog.MountedPlayer.IsMay() && OwningFrog.VOBank != nullptr)
				PlayFoghornVOBankEvent(OwningFrog.VOBank, n"FoghornDBGardenFrogPondRespawnGenericFrogNY", Actor2 = OwningFrog);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"FrogDeathMovement");

			if(!HasControl())
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				MoveData.ApplyConsumedCrumbData(ConsumedParams);
			}

			MoveComp.Move(MoveData);
		}


		// Respawn
		// if(!OwningFrog.bDying)
		// {
		// 	bShouldDeactivate = true;
		// 	OwningFrog.SetActorLocation(RespawnLocation);
		// 	OwningFrog.SetActorRotation(RespawnFwdDirection.ToOrientationRotator());

		// 	OwningFrog.SetAnimBoolParam(n"Respawned", true);

		// 	auto MountedPlayer = OwningFrog.MountedPlayer;
		// 	if(MountedPlayer != nullptr && MountedPlayer.HasControl())
		// 	{
		// 		MountedPlayer.SnapCameraBehindPlayer();
		// 	}
		// }
	}

	bool CheckHitDeathTag(FHitResult Hit, EJumpingFrogDeathType& OutEffectType) const
	{
		if(Hit.Actor != nullptr)
		{
			if(Hit.Actor.IsA(AHazePlayerCharacter::StaticClass()))
			{
				// Nothing with the player can kill a frog
				return false;
			}
			else if(Hit.Actor.ActorHasTag(n"Water"))
			{
				OutEffectType = EJumpingFrogDeathType::Water;
				return true;
			}
			else if(Hit.Actor.ActorHasTag(n"Piercable"))
			{
				OutEffectType = EJumpingFrogDeathType::Piercable;
				return true;
			}
			else if (Hit.Actor.ActorHasTag(n"Slime"))
			{
				OutEffectType = EJumpingFrogDeathType::Slime;
				return true;
			}
			else if(Hit.Component != nullptr)
			{
				if(Hit.Component.HasTag(n"Water"))
				{
					OutEffectType = EJumpingFrogDeathType::Water;
					return true;
				}
				else if(Hit.Component.HasTag(n"Piercable"))
				{
					OutEffectType = EJumpingFrogDeathType::Piercable;
					return true;
				}
				else if(Hit.Component.HasTag(n"Slime"))
				{
					OutEffectType = EJumpingFrogDeathType::Slime;
					return true;
				}
			}
		}
	
		return false;
	}
}