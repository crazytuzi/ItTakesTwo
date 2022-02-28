
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Vino.ActivationPoint.ActivationPointStatics;
import Vino.Pickups.PlayerPickupComponent;

struct FMagnetInfluencerTargetForce
{
	float InputAlpha = 0.f;
	float DistanceAlpha = 0.f;
	bool bIsPositive = false;

	float GetForce()const
	{
		return FMath::Lerp(InputAlpha, 0.f, DistanceAlpha);
	}	
}

struct FMagnetInfluencer
{
	AHazeActor Influencer = nullptr;
	TArray<FName> Instigators;
	private bool bRemoveWhenTargetReached = false;
	private FMagnetInfluencerTargetForce CurrentForce;
	private float CurrentForceAmount = 0.f;
	private TArray<FMagnetInfluencerTargetForce> TargetForces;
	private bool bIsActive = false;

	bool IsActive() const
	{
		if(bIsActive == false)
			return false;

		if(bRemoveWhenTargetReached)
			return false;

		if(Influencer == nullptr)
			return false;
		
		if(Instigators.Num() == 0)
			return false;

		return true;
	}	
	
	bool Update(float DeltaTime)
	{
		if(bIsActive == false)
			return false;

		float TargetForce = 0.f;
		if(TargetForces.Num() > 0)
		{
			FMagnetInfluencerTargetForce& CurrentTarget = TargetForces[0];
			TargetForce = CurrentTarget.GetForce();
		}

		CurrentForceAmount = FMath::FInterpConstantTo(CurrentForceAmount, TargetForce, DeltaTime, 10.f);	
		if(CurrentForceAmount == TargetForce && bRemoveWhenTargetReached && TargetForces.Num() == 0)
		{
			if(TargetForces.Num() > 0)
			{
				CurrentForce = TargetForces[0];
				if(TargetForces.Num() > 1 || bRemoveWhenTargetReached)
				{
					TargetForces.RemoveAt(0);
				}
			}
			bIsActive = false;
			return false;
		}

		return true;
	}

	bool AddTargetForce(bool bAsPositive, float AxisAlpha, float DistanceAlpha)
	{
		bool bAddForce = false;
		if(TargetForces.Num() == 0)
		{
			bAddForce = true;
		}
		else
		{
			const FMagnetInfluencerTargetForce& CurrentTargetForce = TargetForces[0];
			if(CurrentTargetForce.InputAlpha != AxisAlpha)
			{
				bAddForce = true;
			}
			else if(CurrentTargetForce.DistanceAlpha != DistanceAlpha)
			{
				bAddForce = true;
			}
			else if(CurrentTargetForce.bIsPositive != bAsPositive)
			{
				bAddForce = true;
			}
		}

		if(bAddForce)
		{
			TargetForces.Add(FMagnetInfluencerTargetForce());
			FMagnetInfluencerTargetForce& NewForce = TargetForces[TargetForces.Num() - 1];
			NewForce.InputAlpha = AxisAlpha;
			NewForce.bIsPositive = bAsPositive;
			NewForce.DistanceAlpha = DistanceAlpha;
			bRemoveWhenTargetReached = false;
			bIsActive = true;
		}

		return bAddForce;
	}
	
	void RemoveForce()
	{
		if(TargetForces.Num() > 0)
		{
			AddTargetForce(TargetForces[TargetForces.Num() - 1].bIsPositive, 0.f, TargetForces[TargetForces.Num() - 1].DistanceAlpha);		
		}

		bRemoveWhenTargetReached = true;
	}

	float GetPositiveForce()const
	{
		if(CurrentForce.bIsPositive)
			return CurrentForce.GetForce();
		return 0.f;
	}

	float GetNegativeForce()const
	{
		if(!CurrentForce.bIsPositive)
			return CurrentForce.GetForce();
		return 0.f;
	}

	float GetDistanceAlpha()const
	{
		return CurrentForce.DistanceAlpha;
	}

	float GetInputAlpha()const
	{
		return CurrentForce.InputAlpha;
	}
}

struct FReplicatedMagnetInfluencer
{
	UMagneticComponent InstigatorMagnet = nullptr;
	float AxisAlpha = 0.f;
	float DistanceAlpha = 0.f;
}

enum EMagnetPolarity
{
	Plus_Red,
	Minus_Blue,
};

event void FMagneticForceApplied(bool ForceIsPositive, float Magnitude);
event void FMagneticForceStateChanged(bool IsApplyingForce);

class UMagneticComponent : UHazeActivationPoint
{
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default EvaluationInterval = EHazeActivationPointTickIntervalType::EveryForthFrame;
	default bAlwaysValidateInView = true;

	UPROPERTY(Category = "Attribute")
	EMagnetPolarity Polarity = EMagnetPolarity::Plus_Red;

	// This value will be added to the selectable distance
	UPROPERTY(Category = "Attribute", meta = (ClampMin = 0.0))
	private float DeactivationDistanceOffset = 500.f;
	float DeactivationDistance;

	UPROPERTY(DisplayName = "Ignore Attach Parent",  Category = "Line-of-sight")
	bool bIgnoreAttachParentInLineOfSightTest = true;

	UPROPERTY(Category = "Animation")
	bool bUseGenericMagnetAnimation = true;

	UPROPERTY()
	TArray<AHazeActor> DisabledForObjects;

	UPROPERTY()
	bool bIsDisabled = false;

	// Only used if bigger then 0 
	UPROPERTY()
	float DistanceMaxScore = -1;

	// Only used if bigger then 0 
	UPROPERTY()
	float CameraMaxScore = -1;


	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 6000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 3000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 2000.f);
	
	private TArray<FMagnetInfluencer> Influencers;
	private TArray<FReplicatedMagnetInfluencer> ReplicatedInfluences;
	private	float RemaningDelayToReplication = 0.f;

	FMagneticForceApplied ForceDelegate;

	private uint32 LastReplicatedIndex = 0;

	// Useless within self, should be abstract
	void UpdateActiveMagnet(UMagneticComponent ActiveMagnet) { } // virtual

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		DeactivationDistance = GetDistance(EHazeActivationPointDistanceType::Selectable) + DeactivationDistanceOffset;
		SetComponentTickEnabled(true);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		int ActiveCounter = 0;
		for(int i = Influencers.Num() - 1; i >= 0; --i)
		{	
			FMagnetInfluencer& Influencer = Influencers[i];
			if(Influencer.Update(DeltaTime))
				ActiveCounter++;

			UMagneticComponent InfluencerMagneticComponent = UMagneticComponent::Get(Influencer.Influencer);
			if(InfluencerMagneticComponent != nullptr)
				InfluencerMagneticComponent.UpdateActiveMagnet(this);
		}
	
		// Both sides can replicated to the other side depending on the controller of the replication
		if(ReplicatedInfluences.Num() > 0)
		{
			RemaningDelayToReplication -= DeltaTime;
			if(RemaningDelayToReplication <= 0)
			{
				RemaningDelayToReplication = 0.2f;
				NetReplicateInfluenceInternal(HasControl(), ReplicatedInfluences);
				ReplicatedInfluences.Empty();
			}
		}
		else if(ActiveCounter <= 0)
		{
			SetComponentTickEnabled(false);
		}
	}

	UFUNCTION(NetFunction)
	void NetReplicateInfluenceInternal(bool bSenderHasControl, const TArray<FReplicatedMagnetInfluencer>& ReplicatedInfluences)
	{
		if(bSenderHasControl == HasControl())
			return;

		for(const FReplicatedMagnetInfluencer& Replication : ReplicatedInfluences)
		{
			if(Replication.InstigatorMagnet == nullptr)
				continue;
			
			AHazeActor Influencer = Cast<AHazeActor>(Replication.InstigatorMagnet.GetOwner());
			for(int i = 0; i < Influencers.Num(); ++i)
			{
				if(Influencers[i].Influencer != Influencer)
					continue;

				Influencers[i].AddTargetForce(Polarity == Replication.InstigatorMagnet.Polarity, Replication.AxisAlpha, Replication.DistanceAlpha);
				break;
			}

			SetComponentTickEnabled(true);
		}
	}

	// This function implements how the magnets are displayed and grabable
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{
		if(bIsDisabled)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(DisabledForObjects.Contains(Player))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Only render simple viewport positional GUI if magnet is not rendered in player's viewport
		if(!Query.bIsOnScreen)
			return EHazeActivationPointStatusType::Invalid;

		FFreeSightToActivationPointParams SightTestParams;

		SightTestParams.IgnoredActors.Add(Player.OtherPlayer);
		UPlayerPickupComponent PlayerPickupComponent = UPlayerPickupComponent::Get(Player);
		if(PlayerPickupComponent.IsHoldingObject())
			SightTestParams.IgnoredActors.Add(PlayerPickupComponent.CurrentPickup);

		SightTestParams.bIgnoreAttachParent = bIgnoreAttachParentInLineOfSightTest;
		SightTestParams.TraceFromPlayerBone = n"MiddleBrow";

		// Test line-of-sight from player to magnet component
		if(!ActivationPointsStatics::CanPlayerReachActivationPoint_Async(Player, Query, ETraceTypeQuery::Visibility, SightTestParams))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(ShouldInvalidateStatusOnPlayerMagnetPerch() && (Player.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchCapability) || Player.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchPerchCapability)))
			return EHazeActivationPointStatusType::Invalid;

		return EHazeActivationPointStatusType::Valid;
	}

	// Overriding this function to hide a widget whenever the magnet is being used
	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const
	{
		if(Query.IsActive())
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(Query.IsInvalidNotHidden())
			return EHazeActivationPointStatusType::Invalid;

		if(Query.IsTargeted())
			return EHazeActivationPointStatusType::Valid;

		if(Query.IsValid())
			return EHazeActivationPointStatusType::Valid;

		return EHazeActivationPointStatusType::InvalidAndHidden;
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha, DistanceMaxScore, CameraMaxScore);
		return ScoreAlpha;
	}

	float GetNetworkTime(AHazeActor Instigator)const
	{
		if(Instigator.HasControl())
			return FMath::Max(Network::GetPingRoundtripSeconds(), 0.1f);
		else
			return FMath::Max(0.1f - Network::GetPingRoundtripSeconds(), 0.f);
	}

	// This function will add the magnetic force to both network sides from the controlling side
	UFUNCTION()
	void ApplyControlInfluenser(UMagneticComponent InfluencerMagnet, FName Instigator, float AxisAlpha, float DistanceAlpha)
	{
		if(InfluencerMagnet == nullptr)
			return;

		if(Instigator == NAME_None)
			return;

		AHazeActor Influencer = Cast<AHazeActor>(InfluencerMagnet.GetOwner());
		if(Influencer.HasControl() == false)
			return;
	
		for(int i = 0; i < Influencers.Num(); ++i)
		{
			if(Influencers[i].Influencer == Influencer && Influencers[i].Instigators.Contains(Instigator))
			{
				const bool bIsPositive = Polarity == InfluencerMagnet.Polarity;
				if(Influencers[i].AddTargetForce(bIsPositive, AxisAlpha, DistanceAlpha))
				{
					// This is sent over when the replication timer is expired
					AddPendingReplicatedInfluence(InfluencerMagnet, AxisAlpha, DistanceAlpha);
				}

				SetComponentTickEnabled(true);

				// Return out here
				return;
			}
		}

		NetAddNewInstigatorInternal(InfluencerMagnet, Instigator, AxisAlpha, DistanceAlpha);
	}

	UFUNCTION()
	void RemoveInfluenser(AHazeActor Influencer, FName Instigator)
	{
		if(Influencer == nullptr)
			return;

		if(Instigator == NAME_None)
			return;

		for(int i = Influencers.Num() - 1; i >= 0; --i)
		{
			if(Influencers[i].Influencer == Influencer)
			{
				Influencers[i].Instigators.Remove(Instigator);
				if(Influencers[i].Instigators.Num() == 0)
				{
					Influencers[i].RemoveForce();
					Influencers.RemoveAt(i);
				}
			}
		}
	}

	void AddPendingReplicatedInfluence(UMagneticComponent InstigatorMagnet, float AxisAlpha, float DistanceAlpha)
	{
		for(FReplicatedMagnetInfluencer& Replication : ReplicatedInfluences)
		{	
			if(Replication.InstigatorMagnet == InstigatorMagnet && Replication.AxisAlpha != 1.f && Replication.AxisAlpha != 0.f)
			{
				// We cant override the min max values, thoes need to happen
				if(Replication.AxisAlpha != 1.f || Replication.AxisAlpha != 0.f || AxisAlpha == Replication.AxisAlpha)
				{
					Replication.AxisAlpha = AxisAlpha;
					Replication.DistanceAlpha = DistanceAlpha;
				}
		
				// Return out
				return;
			}
		}

		// Add new index;
		FReplicatedMagnetInfluencer ReplicatedInfluence;
		ReplicatedInfluence.InstigatorMagnet = InstigatorMagnet;;
		ReplicatedInfluence.AxisAlpha = AxisAlpha;	
		ReplicatedInfluence.DistanceAlpha = DistanceAlpha;
		ReplicatedInfluences.Add(ReplicatedInfluence);
	}

	UFUNCTION(NetFunction)
	void NetAddNewInstigatorInternal(UMagneticComponent InfluencerMagnet, FName Instigator, float AxisAlpha, float DistanceAlpha)
	{
		AHazeActor Influencer = Cast<AHazeActor>(InfluencerMagnet.GetOwner());
		for(int i = Influencers.Num() - 1; i >= 0; --i)
		{
			if(Influencers[i].Influencer == Influencer)
			{
				Influencers[i].Instigators.Add(Instigator);
				return;
			}
		}
		
		Influencers.Add(FMagnetInfluencer());
		Influencers[Influencers.Num() - 1].Influencer = Influencer;
		Influencers[Influencers.Num() - 1].AddTargetForce(Polarity == InfluencerMagnet.Polarity, AxisAlpha, DistanceAlpha);
		Influencers[Influencers.Num() - 1].Instigators.Add(Instigator);
		SetComponentTickEnabled(true);
		RemaningDelayToReplication = 0.2f;
	}

	UFUNCTION()
	bool HasOppositePolarity(UMagneticComponent Other)const
	{
		return Polarity != Other.Polarity;
	}

	UFUNCTION()
	bool HasEqualPolarity(UMagneticComponent Other)const
	{
		return Polarity == Other.Polarity;
	}

	UFUNCTION()
	bool GetIsPolarityPositive(EMagnetPolarity Type)const
	{
		return Type == EMagnetPolarity::Plus_Red;
	}

	UFUNCTION()
	bool HasPositivePolarity()const
	{
		return GetIsPolarityPositive(Polarity);
	}


	UFUNCTION(BlueprintPure)
	bool IsInfluencedBy(UObject Object)const
	{
		for (FMagnetInfluencer Value : Influencers)
		{
			if (Value.Influencer == Object)
				return Value.IsActive();
		}
		return false;
	}

	bool GetInfluencingPlayers(TArray<AHazePlayerCharacter>& OutPlayers)const
	{
		OutPlayers.Empty();
		for(FMagnetInfluencer Influencer: Influencers)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Influencer.Influencer);
			if (Player == nullptr)
				continue;

			if(Influencer.IsActive() == false)
				continue;

			OutPlayers.Add(Player);
		}

		return OutPlayers.Num() > 0;
	}

	void GetInfluencers(TArray<FMagnetInfluencer>& OutInfluencers)const 
	{
		for(FMagnetInfluencer Influencer: Influencers)
		{
			if(Influencer.IsActive() == false)
				continue;

			OutInfluencers.Add(Influencer);
		}
	}

	int GetInfluencerNum() const property
	{
		int ActiveCount = 0;
		for(const FMagnetInfluencer& Influencer: Influencers)
		{
			if(Influencer.IsActive() == false)
				continue;

			ActiveCount++;
		}
		return ActiveCount;
	}
	
	UFUNCTION()
	bool GetInfluencer(UObject Object, FMagnetInfluencer& Out)
	{
		for (FMagnetInfluencer Value : Influencers)
		{
			if (Value.Influencer != Object)
				continue;

			if(Value.IsActive() == false)
				continue;

			Out = Value;
			return true;		
		}
		return false;
	}

	UFUNCTION(BlueprintPure)
	FVector GetNormalizedDirectionFromAllInfluencers()
	{
		FVector Direction = GetDirectionalForceFromAllInfluencers();
		Direction.Normalize();
		return Direction;
	}

	UFUNCTION(BlueprintPure)
	FVector GetDirectionalForceFromAllInfluencers()
	{
		if (Influencers.Num() == 0)
			return FVector::ZeroVector;

		FVector ResultingDirection;
		for (const FMagnetInfluencer Influencer : Influencers)
		{
			FVector ToInfuencerDir = UMagneticComponent::Get(Influencer.Influencer).WorldLocation - WorldLocation;
			float InfluencerDist = ToInfuencerDir.Size();

			float Difference = InfluencerDist / GetDistance(EHazeActivationPointDistanceType::Selectable);

			float Percentage = 1 - Difference;
			
			if(HasOppositePolarity(UMagneticComponent::Get(Influencer.Influencer)))
			{
				ResultingDirection += ToInfuencerDir.GetSafeNormal() * Percentage;
			}
			else
			{
				ResultingDirection -= ToInfuencerDir.GetSafeNormal() * Percentage;
			}
		}

		return ResultingDirection / Influencers.Num();
	}

	bool IsInCameraView(AHazePlayerCharacter PlayerCharacter) const
	{
		return SceneView::IsInView(PlayerCharacter, WorldLocation);
	}

	protected bool ShouldInvalidateStatusOnPlayerMagnetPerch() const
	{
		return true;
	}
}