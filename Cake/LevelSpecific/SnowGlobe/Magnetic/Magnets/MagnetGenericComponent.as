import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

event void FOnGenericMagnetInteractionStateChanged(bool InteractionActive, UMagnetGenericComponent GenericComponent, AHazePlayerCharacter Player);

UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UMagnetGenericComponent : UMagneticComponent
{
	UPROPERTY()
	UGenericMagnetSettingsDataAsset GenericMagnetSettings;

	UPROPERTY()
	FOnGenericMagnetInteractionStateChanged OnGenericMagnetInteractionStateChanged;

	UPROPERTY()
	bool bShowDotWidgetWhenOccludedAndInRange = false;

	UPROPERTY()
	bool bBlockIfPlayerIsOnTop = true;

	UPROPERTY()
	float GenericForceFeedbackStrength = 0.1f;

	UPROPERTY()
	bool bPullPlayerWhenUnderwater = false;

	UPROPERTY(meta = (EditCondition="bPullPlayerWhenUnderwater"))
	float UnderwaterPullMinRange = 600.f;

	UPROPERTY(meta = (EditCondition="bPullPlayerWhenUnderwater"))
	float UnderwaterPullMaxRange = 1000.f;

	UPROPERTY(meta = (EditCondition="bPullPlayerWhenUnderwater"))
	float UnderwaterConstrainRange = 1200.f;

	UPROPERTY(meta = (EditCondition="bPullPlayerWhenUnderwater"))
	float UnderwaterPullForce = 1200.f;

	UFUNCTION()
	bool IsBlockedByStandingPlayer(AHazePlayerCharacter Player) const
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);

		return (MoveComp.DownHit.Actor == Owner && bBlockIfPlayerIsOnTop);
	}

	// This function implements how the magnets are displayed and grabable-
	UFUNCTION(BlueprintOverride)
    EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
    {
		EHazeActivationPointStatusType ActivationPointType = Super::SetupActivationStatus(Player, Query);
		if(ActivationPointType != EHazeActivationPointStatusType::Valid)
			return ActivationPointType;

		if (IsBlockedByStandingPlayer(Player))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(GenericMagnetSettings != nullptr)
		{
			if(GenericMagnetSettings.bDoExtraVisibilityCheckToBlockParents)
			{
				UMagneticComponent PlayerMagComponent = UMagneticComponent::Get(Player);
				if (IsMagneticPathBlocked(PlayerMagComponent, GenericMagnetSettings.bIgnoreSelf))
				{
					if(bShowDotWidgetWhenOccludedAndInRange && Query.DistanceType == EHazeActivationPointDistanceType::Selectable)
						return EHazeActivationPointStatusType::Invalid;
					else
						return EHazeActivationPointStatusType::InvalidAndHidden;
				}
			}
		}
		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION()
	bool IsMagneticPathBlocked(UMagneticComponent PlayerMagneticComponent, bool IgnoreSelf) const
	{
		FHitResult Hit;
		TArray<AActor> ActorsToIgnore;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(PlayerMagneticComponent.Owner);
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(Player);
		if(PlayerPickupComponent.IsHoldingObject())
			ActorsToIgnore.Add(PlayerPickupComponent.CurrentPickup);

		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Game::GetMay());
		if(IgnoreSelf)
			ActorsToIgnore.Add(Owner);

		System::LineTraceSingle(WorldLocation, PlayerMagneticComponent.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, IgnoreSelf, FLinearColor::Green);

		if(Hit.bBlockingHit)
		{
			return true;
		}
		return false;
	}
	
	UFUNCTION()	
	FVector GetDirectionalForceFromAllInfluencers() override
	{
		FVector ResultingDirection;
		TArray<FMagnetInfluencer> CurrentInfluencers;
		GetInfluencers(CurrentInfluencers);

		if (CurrentInfluencers.Num() == 0)
			return FVector::ZeroVector;

		for (const FMagnetInfluencer Influencer : CurrentInfluencers)
		{
			FVector ToInfuencerDir = UMagneticComponent::Get(Influencer.Influencer).WorldLocation - WorldLocation;
			
			if(HasOppositePolarity(UMagneticComponent::Get(Influencer.Influencer)))
				ResultingDirection += ToInfuencerDir.GetSafeNormal();
			else
				ResultingDirection -= ToInfuencerDir.GetSafeNormal();
		}

		return ResultingDirection / CurrentInfluencers.Num();
	}

	UFUNCTION()
	bool HasFreeSight(AHazePlayerCharacter Player) const
	{
		TArray<AActor> IgnoredActors;
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(Player);
		if(PlayerPickupComponent.IsHoldingObject())
			IgnoredActors.Add(PlayerPickupComponent.CurrentPickup);

		FFreeSightToActivationPointParams SightTestParams;
		SightTestParams.IgnoredActors = IgnoredActors;
		SightTestParams.TraceFromPlayerBone = n"MiddleBrow";

		FHazeQueriedActivationPoint QueryPoint;
		if(Player.GetActivePoint(UMagneticComponent::StaticClass(), QueryPoint))
			return ActivationPointsStatics::CanPlayerReachActivationPoint(Player, QueryPoint, SightTestParams);

		return false;
	}
}

class UGenericMagnetSettingsDataAsset : UDataAsset
{

	UPROPERTY(Category = "Visibility Checks")
	bool bDoExtraVisibilityCheckToBlockParents;
	UPROPERTY(Category = "Visibility Checks")
	bool bIgnoreSelf;
	UPROPERTY(Category = "Visibility Checks")
	bool bOnlyBlockSamePolarityWhenInfluencing;
	UPROPERTY(Category = "Visibility Checks")
	bool bCheckFreeSightWhenInfluencing;

	UPROPERTY(Category = "Magnetism Settings")
	bool bDeactivateWhenDistanceIsLongerThanSelectable = true;
	UPROPERTY(Category = "Magnetism Settings")
	bool bDeactivateWhenDistanceIsLongerThanCustomDistance;
	UPROPERTY(Category = "Magnetism Settings")
	float CustomDistance = 2000.0f;	
	UPROPERTY(Category = "Magnetism Settings")
	bool bConstrainPlayerToDistance;

	UPROPERTY(Category = "PlayerMovement")
	bool bShouldSlowPlayer = false;
	UPROPERTY(Category = "PlayerMovement")
	float PlayerMovementSpeed = 500.f;
	
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect StartUpRumble;
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect ConstantRumble;
}