import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;
event void FOnGroundPoundBounce();

UCLASS(HideCategories = "ComponentTick Activation Cooking ComponentReplication Variable Tags AssetUserData Collision")
class UChasingMoleBounceComponent : UActorComponent
{
    UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1600.f;
  
    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;
   
    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent BounceEvent;

	UPROPERTY()
    FOnGroundPoundBounce OnGroundPoundBounce;
	
	AHazeActor HazeOwner;
	UHazeAkComponent HazeAkComponent;

	const float SmallMoveDistanceValue = 15.f;
	const float GroundPoundMoveDistanceValue = 200;
	const float FinalMoveDistance = 1400.f;
	const float MaxDistanceBeforeFinalGroundPound = 2350;
	const float MoveSpeed = 1.f / 0.15f;
	float MoveSpeedMultiplier = 1;

	float TargetMoveDistance = 0;
	float MoleMoveDistance = 0;
	
	bool bCanApplyFinalGroundPound = false;
	private bool bFinished = false;
	private bool bCodyIsWaitingForCrumbs = false;
	private bool bMayIsWaitingForCrumbs = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		HazeAkComponent = Cast<UHazeAkComponent>(HazeOwner.GetOrCreateComponent(UHazeAkComponent::StaticClass()));

		FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnMole");
        BindOnDownImpactedByPlayer(HazeOwner, OnPlayerLanded);
		UActorImpactedCallbackComponent CallbackComp = UActorImpactedCallbackComponent::Get(HazeOwner);
		CallbackComp.bCanBeActivedLocallyOnTheRemote = true; // No need to network this. We are using crumbs instead

		// Cody
		{
			auto Player = Game::GetCody();
			auto CrumbComp = UHazeCrumbComponent::Get(Player);
			CrumbComp.MakeCrumbsUseCustomWorldCalculator(UMoleBounceLocationCalculator::StaticClass(), this, UHazeSkeletalMeshComponentBase::Get(HazeOwner));
		}

		// May
		{
			auto Player = Game::GetMay();
			auto CrumbComp = UHazeCrumbComponent::Get(Player);
			CrumbComp.MakeCrumbsUseCustomWorldCalculator(UMoleBounceLocationCalculator::StaticClass(), this, HazeOwner.RootComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Reset(bWithCrumb = false);
	}

	void Reset(bool bWithCrumb = true)
	{
		if(bWithCrumb)
		{
			// Cody
			if(!bCodyIsWaitingForCrumbs)
			{
				bCodyIsWaitingForCrumbs = true;
				auto Player = Game::GetCody();
				auto CrumbComp = UHazeCrumbComponent::Get(Player);
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"Player", Player);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Reset"), CrumbParams);
			}

			// May
			if(!bMayIsWaitingForCrumbs)
			{
				bMayIsWaitingForCrumbs = true;
				auto Player = Game::GetMay();
				auto CrumbComp = UHazeCrumbComponent::Get(Player);
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"Player", Player);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_Reset"), CrumbParams);
			}
		}
		else
		{
			// Cody
			if(!bCodyIsWaitingForCrumbs)
			{
				ResetCrumbComp(Game::GetCody());
			}

			// May
			if(!bMayIsWaitingForCrumbs)
			{
				ResetCrumbComp(Game::GetMay());
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_Reset(const FHazeDelegateCrumbData& CrumbData)
	{
		auto Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		if(Player.IsCody())
			bCodyIsWaitingForCrumbs = false;
		else
			bMayIsWaitingForCrumbs = false;

		ResetCrumbComp(Player);
	}

	private void ResetCrumbComp(AHazePlayerCharacter Player)
	{
		auto CrumbComp = UHazeCrumbComponent::Get(Player);
		CrumbComp.RemoveCustomWorldCalculator(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const float NewMoveDistance = FMath::FInterpTo(MoleMoveDistance, TargetMoveDistance, DeltaTime, MoveSpeed * MoveSpeedMultiplier);
		const float MinMoveAmount = 5.f * DeltaTime;
		
		// The closer we reach the target, the closer to no movement we get. This will prevent that
		float MoveAmount = NewMoveDistance - MoleMoveDistance;
		if(MoveAmount < MinMoveAmount)
			MoveAmount = FMath::Min(MinMoveAmount, TargetMoveDistance - MoleMoveDistance);
	
		MoleMoveDistance += MoveAmount;
		bCanApplyFinalGroundPound = MoleMoveDistance >= MaxDistanceBeforeFinalGroundPound - KINDA_SMALL_NUMBER;
		FVector FinalLocation = Owner.GetActorLocation();
		FinalLocation.Z -= MoveAmount;

		Owner.SetActorLocation(FinalLocation);
	}

	UFUNCTION(NotBlueprintCallable)
    void PlayerLandedOnMole(AHazePlayerCharacter Player, FHitResult HitResult)
    {
		if(HitResult.Actor != Owner)
			return;

		if(bFinished)
			return;

		if(!Player.HasControl())
			return;

		bool bGroundPounded = false;
        if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
            bGroundPounded = true;

		auto PlayerCrumb = UHazeCrumbComponent::Get(Player);
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Player", Player);
		CrumbParams.AddValue(n"Random", FMath::RandRange(0.8f, 1.f));

		if(bGroundPounded)
		{
			CrumbParams.AddActionState(n"GroundPounded");
			if(bCanApplyFinalGroundPound)
			{
				MoveSpeedMultiplier = 0.72f;
				CrumbParams.AddActionState(n"FinalGroundPound");
				NetPlayFinalBump();
			}
			else
			{
				OnGroundPoundBounce.Broadcast();
				NetPlayBigBump();
			}
		}
		else
		{
			NetPlaySmallBump();
		}

		PlayerCrumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_MoleBounce"), CrumbParams);
    }

	UFUNCTION(NetFunction)
	void NetPlayFinalBump()
	{
		HazeOwner.SetAnimBoolParam(n"MoleStuckFinalBump", true);
	}
	UFUNCTION(NetFunction)
	void NetPlayBigBump()
	{
		HazeOwner.SetAnimBoolParam(n"MoleStuckBumgBig", true);
	}
		UFUNCTION(NetFunction)
	void NetPlaySmallBump()
	{
		HazeOwner.SetAnimBoolParam(n"MoleStuckBumpSmall", true);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_MoleBounce(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		const bool bGroundPounded = CrumbData.GetActionState(n"GroundPounded") ? true : false;
		const bool bFinalGroundPound = CrumbData.GetActionState(n"FinalGroundPound") ? true : false;

		if(bFinalGroundPound)
		{
			CalculateMoveFinalDistance();
		}
		else
		{
			Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
			Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
			HazeAkComponent.HazePostEvent(BounceEvent); 

			// Have we reached the end and is waiting for the groundpound
			if(bCanApplyFinalGroundPound)
			{
				// Small random factor. The mole is locked so the random factor don't mather
				const float BounceAmount = FMath::Lerp(0.f, VerticalVelocity, FMath::RandRange(0.7f, 0.8f));
				Player.SetCapabilityAttributeValue(n"VerticalVelocity", BounceAmount);
			}
			else
			{
				// Small random factor. Because this moves the mole, we need to send it in network
				const float BounceAmount = FMath::Lerp(0.f, VerticalVelocity, CrumbData.GetValue(n"Random"));
				if(bGroundPounded)
				{
					Player.SetCapabilityAttributeValue(n"VerticalVelocity", BounceAmount * 0.76f);
					CalculateMoveGroundPound();
				}		
				else
				{
					Player.SetCapabilityAttributeValue(n"VerticalVelocity", BounceAmount);
					CalculateMoveFall();
				}		
			}
		}
	}

	void CalculateMoveGroundPound()
	{
		const float MaxMove = MaxDistanceBeforeFinalGroundPound - MoleMoveDistance;
		TargetMoveDistance += FMath::Min(GroundPoundMoveDistanceValue, MaxMove);
	}

	void CalculateMoveFall()
	{
		const float MaxMove = MaxDistanceBeforeFinalGroundPound - MoleMoveDistance;
		TargetMoveDistance += FMath::Min(SmallMoveDistanceValue, MaxMove);
	}
	
	void CalculateMoveFinalDistance()
	{
		if(!bFinished)
		{
			TargetMoveDistance += FinalMoveDistance;
			bFinished = true;
			Owner.SetActorEnableCollision(false);
		}
	}

	bool IsFinished()const
	{
		if(!bFinished)
			return false;

		if(MoleMoveDistance < (MaxDistanceBeforeFinalGroundPound + FinalMoveDistance) - KINDA_SMALL_NUMBER)
			return false;

		return true;
	}
}


class UMoleBounceLocationCalculator : UHazeReplicationLocationCalculator
{
	AHazePlayerCharacter PlayerOwner = nullptr;
	USceneComponent RelativeComponent = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor Owner, USceneComponent InRelativeComponent)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		RelativeComponent = InRelativeComponent;
	}

	UFUNCTION(BlueprintOverride)
	void OnReset(FHazeActorReplicationFinalized CurrentParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		//OutTargetParams.Location = PlayerOwner.GetActorLocation();
		OutTargetParams.CustomLocation = OutTargetParams.Location - RelativeComponent.GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		const FVector RelativeLocation = RelativeComponent.GetWorldLocation();
		TargetParams.Location = RelativeLocation + TargetParams.CustomLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime, FHazeActorReplicationFinalized CurrentParams)
	{
			
	}
}
