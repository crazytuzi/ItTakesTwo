import bool IsAiming(AActor) from "Cake.LevelSpecific.Music.MusicTargetingComponent";
import bool MusicTargetingTrace(AHazePlayerCharacter, const UMusicImpactComponent, FHazeHitResult&) from "Cake.LevelSpecific.Music.MusicTargetingComponent";
import Vino.ActivationPoint.ActivationPointStatics;

enum EMusicImpactIconVisibilityType
{
	Always,
	OnlyDuringAiming,
	OnlyDuringNotAiming,
}

struct FMusicHitResult
{
	UMusicImpactComponent ImpactComponent;
	
	private FHazeHitResult HitResult;
	private FVector ImpactPoint;
	private AHazePlayerCharacter Player;
	private bool bIsValidImpact = false;

	FMusicHitResult(AHazePlayerCharacter InPlayer, UMusicImpactComponent Component = nullptr)
	{
	 	ImpactComponent = Component;
		Player = InPlayer;
	}

	FMusicHitResult(AHazePlayerCharacter InPlayer, UMusicImpactComponent Component, const FHazeHitResult& ValidHitResult)
	{
	 	Player = InPlayer;
		ImpactComponent = Component;
		HitResult = ValidHitResult;
		if(ValidHitResult.bBlockingHit)
			ImpactPoint = ValidHitResult.ImpactPoint;
		else
			ImpactPoint = ValidHitResult.FHitResult.TraceEnd;
		
		bIsValidImpact = true;
	}

	// This is a replicated data, so we say that the trace is always valid
	FMusicHitResult(AHazePlayerCharacter InPlayer, UMusicImpactComponent Component, FVector _ImpactPoint, FVector _ImpactNormal)
	{
		Player = InPlayer;
		ImpactComponent = Component;
		ImpactPoint = _ImpactPoint;
		if(Component != nullptr)
			HitResult.OverrideFHitResult(FHitResult(Component.Owner, nullptr, _ImpactPoint, _ImpactNormal));
		else
			HitResult.OverrideFHitResult(FHitResult(nullptr, nullptr, _ImpactPoint, _ImpactNormal));

		bIsValidImpact = true;
	}

	void UpdateImpactPoint(FVector NewPoint)
	{
		ImpactPoint = NewPoint;
	}

	FVector GetImpactLocation() const property
	{
		return ImpactPoint;
	}

	bool IsValid()const
	{
		if(ImpactComponent == nullptr)
			return false;

		if(!bIsValidImpact)
			return false;

		if(!ImpactComponent.IsValidTarget())
			return false;

		if(!ImpactComponent.PlayerCanValidate(Player))
			return false;

		return true;
	}
}

UCLASS(Abstract)
class UMusicImpactComponent : UHazeActivationPoint
{
	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 0.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 0.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 0.f);
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;

	UPROPERTY()
	bool bCanBeTargeted = true;

	UPROPERTY(Category = Attribute)
	bool bVisibilityCheck = false;

	// We start at half so we can bring it up or down
	UPROPERTY(EditDefaultsOnly, Category = Attribute)
	float BonusScoreMultiplier = 0.5f;

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{			
		if(!IsValidTarget())
		{
			return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		if(bVisibilityCheck)
		{
			FFreeSightToActivationPointParams Params;
			Params.IgnoredActors.Add(Player);
			Params.IgnoredActors.Add(Player.OtherPlayer);
			Params.TraceFromPlayerBone = n"Head";

			if(!ActivationPointsStatics::CanPlayerReachActivationPoint_Async(Player, Query, ETraceTypeQuery::Visibility, Params))
			{
				return EHazeActivationPointStatusType::InvalidAndHidden;
			}
		}

		const bool bIsAiming = IsAiming(Player);
		if(!bIsAiming)
		{
			return EHazeActivationPointStatusType::Invalid;
		}

		if(Query.DistanceType != EHazeActivationPointDistanceType::Selectable)
		{
			return EHazeActivationPointStatusType::Invalid;
		}

		FHazeHitResult OutHitResult;
		const bool bIsValid = MusicTargetingTrace(Player, this, OutHitResult);
		Query.StoreTraceResult(OutHitResult);

		if(!bIsValid)
		{
			return EHazeActivationPointStatusType::Invalid;
		}

		return EHazeActivationPointStatusType::Valid;
	}


	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, const FHazeQueriedActivationPointWithWidgetInformation& Query) const
	{
		const bool bIsAiming = IsAiming(Player);

		if(!bIsAiming)
			return EHazeActivationPointStatusType::Invalid;
	 	
		return EHazeActivationPointStatusType::Valid;
	}

	bool IsValidTarget() const
	{
		return bCanBeTargeted;
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
	
		const float Multiplier = 1.f;
		return FinalScore * Multiplier * BonusScoreMultiplier;
	}

	UFUNCTION(meta = (DeprecatedFunction, DeprecationMessage="Set CanBeTargeted to true/false instead."))
	void SetWidgetVisible(bool bValue)
	{
		bCanBeTargeted = bValue;
	}

	UFUNCTION(BlueprintPure, meta = (DeprecatedFunction, DeprecationMessage="Check CanBeTargeted instead."))
	bool IsWidgetVisible() const { return bCanBeTargeted; }
}
