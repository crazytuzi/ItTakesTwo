import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Peanuts.Aiming.AutoAimTarget;
import Vino.ActivationPoint.ActivationPointStatics;
import Peanuts.Aiming.AutoAimStatics;

event void FVineEvent();

enum EVineImpactIconVisibilityType
{
	Always,
	OnlyDuringAiming,
	OnlyDuringNotAiming,
}

enum EVineActiveType
{
	Inactive,
	PreExtending,
	Extending,
	Retracting,
	ActiveAndLocked
}

import bool IsAimingWithVine(AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.Vine.VineComponent";
import EVineActiveType GetVineActiveType(AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.Vine.VineComponent";
import UVineImpactComponent GetVineImpactComponent(AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.Vine.VineComponent";
import void ForceReleaseVineIfAttachedToImpactComponent(UVineImpactComponent) from "Cake.LevelSpecific.Garden.Vine.VineComponent";
import bool OwnerIsSickleEnemeyAndDead(const UVineImpactComponent) from "Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy";

UCLASS(HideCategories = "AutoActivate Cooking Tags AssetUserData Collision Rendering Activation Physics LOD")
class UVineImpactComponent : UHazeActivationPoint
{
	default EvaluationInterval = EHazeActivationPointTickIntervalType::EveryOtherFrame;
	default ValidationType = EHazeActivationPointActivatorType::Cody;
	default WidgetClass =  Asset("/Game/Blueprints/LevelSpecific/Garden/Vine/WBP_VineImpactIcon.WBP_VineImpactIcon_C");
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default BiggestDistanceType = EHazeActivationPointDistanceType::Targetable;
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 6000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 4500.f);

	UPROPERTY(Category = "Events")
	FVineEvent OnVineWhipped;

	UPROPERTY(Category = "Events")
	FVineEvent OnVineConnected;

	UPROPERTY(Category = "Events")
	FVineEvent OnVineDisconnected;

	UWaterHoseImpactComponent WaterHoseImpactComp;

	UPROPERTY(Category = "Attachment")
	EVineAttachmentType AttachmentMode = EVineAttachmentType::Component;

	UPROPERTY(Category = "Attachment")
	bool bRequireFullyWatered = false;

	UPROPERTY(Category = "Attachment", meta = (EditCondition="AttachmentMode != EVineAttachmentType::Whip"))
	bool bUpdateValidTraceWhileActive = true;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect AttachedForceFeedback = nullptr;

	UPROPERTY(Category = "ForceFeedback")
	bool bLoopAttachedForceFeedback = false;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect WhippedForceFeedback = nullptr;

	UPROPERTY(Category = "Attribute|Widget", meta = (EditCondition="AttachmentMode == EVineAttachmentType::Whip"))
	EVineImpactIconVisibilityType IconVisibilityType = EVineImpactIconVisibilityType::Always;

	UPROPERTY(Category = "Attribute|Widget", meta = (EditCondition="AttachmentMode == EVineAttachmentType::Whip"))
	bool bOnlyWhipShowIconIfTargeted = false;

	UPROPERTY(Category = "Attribute|Widget")
	bool bOnlyShowIconIfAiming = false; 

	// We start at half so we can bring it up or down
	UPROPERTY(EditDefaultsOnly, Category = "Attribute")
	float BonusScoreMultiplier = 0.5f;

	// If >= 0, will show the radial progress
	UPROPERTY()
	float CurrentWidgetRadialProgress = -1;

	private bool bIsValidTarget = true;
	bool bVineAttached = false;

	private TArray<UObject> BlockActivationInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterHoseImpactComp = UWaterHoseImpactComponent::Get(Owner);
		if (WaterHoseImpactComp != nullptr)
		{
			WaterHoseImpactComp.OnFullyWatered.AddUFunction(this, n"FullyWatered");
			if (bRequireFullyWatered)
				bIsValidTarget = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		ForceReleaseVineIfAttachedToImpactComponent(this);
	}

	UFUNCTION()
	void FullyWatered()
	{
		if (bRequireFullyWatered)
			bIsValidTarget = true;
	}

	bool IsValidTarget() const
	{
		if(!bIsValidTarget)
			return false;
		
		if(BlockActivationInstigators.Num() > 0)
			return false;

		if(OwnerIsSickleEnemeyAndDead(this))
			return false;

		if(!PlayerCanValidate(Game::GetCody()))
            return false;
		
		return true;
	}

	void VineHit() const
	{
		auto Cody = Game::GetCody();
		if(Cody != nullptr)
		{
			OnVineWhipped.Broadcast();
			Cody.SetCapabilityActionState(n"AudioVineCrack", EHazeActionState::ActiveForOneFrame);
		}
	}

	void VineConnected()
	{
		if(!bVineAttached)
		{
			bVineAttached = true;

			auto Cody = Game::GetCody();
			if(Cody != nullptr)
			{
				OnVineConnected.Broadcast();
				Cody.SetCapabilityActionState(n"AudioVineImpact", EHazeActionState::ActiveForOneFrame);
			}
		}
	}

	void VineDisconnected()
	{
		if(bVineAttached)
		{
			bVineAttached = false;
			OnVineDisconnected.Broadcast();
		}	
	}

	UFUNCTION()
	void SetCanActivate(bool bNewStatus, UObject Instigator = nullptr)
	{
		UObject BlockerInstigator = Instigator;
		if(BlockerInstigator == nullptr)
			BlockerInstigator = this;

		const int ArrayIndex = BlockActivationInstigators.FindIndex(Instigator);
		if(bNewStatus == false)
		{
			// Want to block but this object is already blocking
			if(ArrayIndex >= 0)
				return;

			BlockActivationInstigators.Add(Instigator);
			if(BlockActivationInstigators.Num() == 1 && bVineAttached)
			{
				Game::GetCody().SetCapabilityActionState(n"ForceVineRelease", EHazeActionState::ActiveForOneFrame);
			}
		}
		else
		{
			// Wants to unblock but this object no longer blocks
			if(ArrayIndex < 0)
				return;

			BlockActivationInstigators.RemoveAtSwap(ArrayIndex);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		if(!IsValidTarget())
		{
			return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		if(!IsAimingWithVine(Player))
		{
			return EHazeActivationPointStatusType::Invalid;
		}

		const EVineActiveType VineActiveType = GetVineActiveType(Player);
		if(VineActiveType == EVineActiveType::Inactive)
		{
			if(Query.DistanceType != EHazeActivationPointDistanceType::Selectable)
			{
				return EHazeActivationPointStatusType::Invalid;
			}
		}

		if(GetVineImpactComponent(Player) != this)
		{
			return EHazeActivationPointStatusType::Invalid;
		}

		FVector DirToPoint = (Query.Transform.GetLocation() - Player.ViewLocation).GetSafeNormal();
		float Dot = DirToPoint.DotProduct(Player.ViewRotation.Vector());
		if(Dot < 0.7f)
		{
			return EHazeActivationPointStatusType::Invalid;
		}
		
		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const
	{
		//const bool bIsTheOne = GetCurrentVineImpactComponent(Player) == this;
		const bool bIsTheOne = false;
		if(bOnlyWhipShowIconIfTargeted && AttachmentMode == EVineAttachmentType::Whip)
		{
			if(!bIsTheOne)
				return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		const bool bIsAiming = IsAimingWithVine(Player);
		if(bOnlyShowIconIfAiming && !bIsAiming)
			return EHazeActivationPointStatusType::InvalidAndHidden;
			
		if(!bIsAiming)
			return EHazeActivationPointStatusType::Invalid;

		if(IconVisibilityType != EVineImpactIconVisibilityType::Always)
		{
			if(bIsAiming && IconVisibilityType == EVineImpactIconVisibilityType::OnlyDuringNotAiming)
				return EHazeActivationPointStatusType::InvalidAndHidden;
			else if(!bIsAiming && IconVisibilityType == EVineImpactIconVisibilityType::OnlyDuringAiming)
				return EHazeActivationPointStatusType::InvalidAndHidden;
		}
	 	
		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		// DISTANCE SCORE
		const float DistanceScore = FMath::Max(1.f - CompareDistanceAlpha, 0.f) * 0.8f;
		
		// ANGLE SCORE
		FVector DirToPoint = (Query.Point.GetWorldLocation() - Player.GetViewLocation()).GetSafeNormal();
		if(DirToPoint.IsNearlyZero())
			DirToPoint = Player.GetViewRotation().ForwardVector;

		float AngleScore = DirToPoint.DotProduct(Player.GetViewRotation().ForwardVector);

		// FINAL SCORE
		float FinalScore = (DistanceScore + AngleScore) * 0.5f;
		//const float Multiplier = GetCurrentVineImpactComponent(Player) == this ? 1.0f : 0.95f;
		const float Multiplier = 1.f;
		return FinalScore * Multiplier * BonusScoreMultiplier;
	}

	bool ShouldUpdateTrace() const
	{
		if(!bUpdateValidTraceWhileActive)
			return false;

		if(AttachmentMode == EVineAttachmentType::Whip)
			return false;
		
		return true;
	}
}

UCLASS(abstract)
class UVineImpactComponentActivationPointWidget : UHazeActivationPointWidget
{
	UPROPERTY(BlueprintReadOnly)
	UVineImpactComponent OwningVinePoint;

	UPROPERTY(BlueprintReadOnly)
	float CurrentWidgetRadialProgress = -1;

	UPROPERTY(BlueprintReadOnly)
	bool bIsHoldInteraction;

	UPROPERTY(BlueprintReadOnly)
	bool bHiddenUntilActiveAim = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		OwningVinePoint = Cast<UVineImpactComponent>(GetOwningPoint());
		bIsHoldInteraction = OwningVinePoint.AttachmentMode != EVineAttachmentType::Whip;
	}

	UFUNCTION(BlueprintOverride)
	void InitializeForQuery(FHazeQueriedActivationPoint Query, EHazeActivationPointWidgetStatusType InVisibility)
	{
		auto VinePoint = Cast<UVineImpactComponent>(Query.Point);
		//auto VinePoint = GetCurrentVineImpactComponent(Game::GetCody());
		//const bool bIsTheOne = VinePoint == OwningVinePoint;
		const bool bIsTheOne = false;
		if(!bIsTheOne)
			CurrentWidgetRadialProgress = -1;
		else if(VinePoint.AttachmentMode == EVineAttachmentType::Whip)
			CurrentWidgetRadialProgress = -1;
		else
			CurrentWidgetRadialProgress = OwningVinePoint.CurrentWidgetRadialProgress;
	}
}

enum EVineAttachmentType
{
	Component,
	HitLocation,
	Whip
}