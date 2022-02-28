
import Vino.Pierceables.PierceStatics;
import Cake.Weapons.Nail.NailWeaponStatics;
import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailSocketDefinition;
import Vino.Movement.Components.MovementComponent;
import Vino.Characters.PlayerCharacter;
import Vino.Audio.VO.NailWielderVOComponent;
import Peanuts.Foghorn.FoghornStatics;

/**
 * Will recall Nail actors that have previously been equipped by the wielder
 */

UCLASS(abstract)
class UNailRecallerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NailRecall");
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	// Should be first or last?
	default TickGroupOrder = 110;
	// default TickGroupOrder = 160;

	// Defaults 
	//////////////////////////////////////////////////////////////////////////
	// Setting 

	float MinimumTimeToRecallAllNails = 0.8f;
	float RecallAllNailsTimer_Threshold = 0.4f;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transient 

	float SubStepFixedDeltaTime = 0.f;
	float TimeToProcess = 0.f;
	bool bRecallAllNails = false;
	float RecallAllNailsTimer = 0.f;
	bool bTriggeredTotalRecall = false;
	float TimeStampShortWhistle = 0.f;

	UHazeMovementComponent MoveComp = nullptr;
	UNailWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;
	UHazeCrumbComponent CrumbComp = nullptr;
	UHazeInputButton ClosestThrownNailWidget = nullptr;

	// Transient 
	//////////////////////////////////////////////////////////////////////////
	// Capability Functions

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UNailWielderComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// if(IsActioning(CapabilityTags::Interaction))
		// 	return EHazeNetworkActivation::DontActivate;

		if(!WielderComp.IsOwnerOfNails())
			return EHazeNetworkActivation::DontActivate;

		if(WielderComp.IsRecallCooldownActive())
			return EHazeNetworkActivation::DontActivate;

 		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
//		if(IsActioning(CapabilityTags::Interaction))
//			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!WielderComp.IsOwnerOfNails())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		WielderComp.TimeStampRecallTagUnblocked = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RecallAllNailsTimer = 0.f;

		// we'll have to snap ongoing recalls incase we get blocked 
		WielderComp.ForceFinishNailRecallForAllNails();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Handle player recalls and external script recall requests
		if(HasControl())
			ProcessNailRecallRequests(DeltaTime);

		// holding down the recall button will trigger all nails to be 
		// recalled automatically in short time intervals
		if(bRecallAllNails)
			AutoTriggerNailRecallsOverTime(DeltaTime);

		// update the lerp path for the recalled nail
		WielderComp.UpdateNailRecallMovement(DeltaTime);

		// for Animation
		WielderComp.SetAnimBoolParamOnAll(n"RecallingSingleNail", WielderComp.IsRecallingSingleNail());
		WielderComp.SetAnimBoolParamOnAll(n"RecallingAllNails", WielderComp.IsRecallingAllNails());
	}

	void ProcessNailRecallRequests(const float DeltaTime)
	{
		// handle external recall requests
		if(WielderComp.NailRecallQueue.Num() != 0)
		{
			for (int i = WielderComp.NailRecallQueue.Num() - 1; i >= 0; --i)
			{
				// we network it here because we need to ensure that 
				// the network call happens on this actors network channel 
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"NailRecallRequest", WielderComp.NailRecallQueue[i]);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbProcessRecallNailRequest"), CrumbParams);
			}
		}

		// Recall Single nail (upon pressing the key once)
		if (WasActionStarted(ActionNames::WeaponReload) && WielderComp.NailsThrown.Num() > 0)
		{
			ANailWeaponActor NailToRecall = WielderComp.NailsThrown.Last();

			if (NailToRecall == nullptr)
			{
				devEnsure(false, "Wops.. Nails are being Destroyed!? We should Disable nails not destroy them. Pls notify Sydney or Per about this");
				return;
			}
			
			// if (WielderComp.MultipleNailsHaveBeenThrown() && WielderComp.bAiming)
			if (WielderComp.MultipleNailsHaveBeenThrown())
			{
				ANailWeaponActor ClosestNail = GetNailClosestToCrosshair();
				if (ClosestNail != nullptr)
				{
					NailToRecall = ClosestNail;
				}
			}

			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"NailToBeRecalled", NailToRecall);
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbRecallNail"), CrumbParams);
		}

		// Process request to recall all nails
		if (IsActioning(ActionNames::WeaponReload) && WielderComp.NailsThrown.Num() > 0)
		{				
			RecallAllNailsTimer += DeltaTime;
			if (RecallAllNailsTimer > RecallAllNailsTimer_Threshold && bTriggeredTotalRecall == false)
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbRecallAllNails"), CrumbParams);

				RecallAllNailsTimer = 0.f;
				bTriggeredTotalRecall = true;
			}
		}
		else
		{
			bTriggeredTotalRecall = false;
			RecallAllNailsTimer = 0.f;
		}
	}

  	UFUNCTION()
	void CrumbRecallAllNails(const FHazeDelegateCrumbData& CrumbData)
	{
		UNailWielderVOComponent VOComp = UNailWielderVOComponent::Get(Owner);
		APlayerCharacter PlayerChar = Cast<APlayerCharacter>(Owner);
		PlayFoghornEffort(VOComp.Long_Whistle, PlayerChar);
		bRecallAllNails = true;
	}

	void AutoTriggerNailRecallsOverTime(const float Dt)
	{
		// Simplified version of: 1 second / (NumNails / time)
		SubStepFixedDeltaTime = FMath::Max(
			MinimumTimeToRecallAllNails / WielderComp.GetNumNailsOwnedByWielder(),
			KINDA_SMALL_NUMBER
		);

		TimeToProcess += Dt;

		while (TimeToProcess >= SubStepFixedDeltaTime && WielderComp.NailsThrown.Num() > 0)
		{
			WielderComp.RecallNail(WielderComp.NailsThrown.Last());
			TimeToProcess -= SubStepFixedDeltaTime;
		}

		if(WielderComp.NailsThrown.Num() <= 0)
			bRecallAllNails = false;
	}

   	UFUNCTION()
	void CrumbProcessRecallNailRequest(const FHazeDelegateCrumbData& CrumbData)
	{
		ANailWeaponActor NailToBeRecalled = Cast<ANailWeaponActor>(CrumbData.GetObject(n"NailRecallRequest"));

		UNailWielderVOComponent VOComp = UNailWielderVOComponent::Get(Owner);
		APlayerCharacter PlayerChar = Cast<APlayerCharacter>(Owner);
		if(Time::GetGameTimeSince(TimeStampShortWhistle) > 1.f)
		{
			PlayFoghornEffort(VOComp.Short_Whistle, PlayerChar);
			TimeStampShortWhistle = Time::GetGameTimeSeconds();
		}
		else
		{
			PlayFoghornEffort(VOComp.Long_Whistle, PlayerChar);
		}

		WielderComp.RecallNail(NailToBeRecalled);
		WielderComp.NailRecallQueue.Remove(NailToBeRecalled);
	}

   	UFUNCTION()
	void CrumbRecallNail(const FHazeDelegateCrumbData& CrumbData)
	{
		ANailWeaponActor NailToBeRecalled = Cast<ANailWeaponActor>(CrumbData.GetObject(n"NailToBeRecalled"));

		UNailWielderVOComponent VOComp = UNailWielderVOComponent::Get(Owner);
		APlayerCharacter PlayerChar = Cast<APlayerCharacter>(Owner);
		if(Time::GetGameTimeSince(TimeStampShortWhistle) > 1.f)
		{
			PlayFoghornEffort(VOComp.Short_Whistle, PlayerChar);
			TimeStampShortWhistle = Time::GetGameTimeSeconds();
		}
		else
		{
			PlayFoghornEffort(VOComp.Long_Whistle, PlayerChar);
		}

		WielderComp.RecallNail(NailToBeRecalled);
	}

	ANailWeaponActor GetNailClosestToCrosshair()
	{
		ANailWeaponActor ClosestNail = nullptr;

		const FVector LineStart = Player.GetPlayerViewLocation();
		const FVector LineDirection = Player.GetPlayerViewRotation().Vector();

		// Get closest nail within Circle 
// 		const float CosAngle = FMath::Cos(FMath::DegreesToRadians(RecallTraceAngle_DEG));
// 		ClosestNail = WielderComp.GetClosestNailThrownWithinConeAngle(LineStart, LineDirection, CosAngle);

		// Get closest nail to line instead
		if (ClosestNail == nullptr)
		{
			// ClosestNail = WielderComp.GetClosestNailThrownToLineDirection(LineStart, LineDirection);
			ClosestNail = WielderComp.GetClosestRecallableNailToLineDirection(LineStart, LineDirection);
		}

		return ClosestNail;
	}

}

