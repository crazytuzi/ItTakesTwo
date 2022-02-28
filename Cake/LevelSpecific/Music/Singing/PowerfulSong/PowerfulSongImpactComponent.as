import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongInfo;
import Cake.LevelSpecific.Music.Singing.SingingSettings;
import Peanuts.Aiming.AutoAimStatics;

import bool IsPointInsideCone(AHazePlayerCharacter, const FVector& Point) from "Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent";
import bool FindClosestPointOnImpact(AHazePlayerCharacter, const UDEPRECATED_PowerfulSongImpactComponent ImpactComponent, FVector& ClosestPoint) from "Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent";

UCLASS(Deprecated, hidecategories = "Collision AssetUserData ComponentReplication Activation Rendering Tags Physics", meta = (DeprecationMessage = "Use SongReactionComponent instead"))
class UDEPRECATED_PowerfulSongImpactComponent : UHazeActivationPoint
{
	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 0.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 0.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 0.f);
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default ValidationType = EHazeActivationPointActivatorType::May;

	UPROPERTY(Category = PowerfulSong)
	bool bBlockPowerfulSong = true;

	UPROPERTY(Category = PowerfulSong)
	bool bAbsorbPowerfulSong = false;

	FHazeAcceleratedVector WorldLocationCurrent;
	FVector WorldLocationTarget;

	UPROPERTY()
	FOnPowerfulSongImpact OnPowerfulSongImpact;

	// Widget will be invalid and hidden until aim over target is successful.
	UPROPERTY(Category = Widget)
	bool bOnlyShowIndicatorOnAutoAim = false;

	private bool bPowerfulSongImpactDisabled = false;

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		if(bPowerfulSongImpactDisabled)
		{
			return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		USingingSettings SingingSettings = USingingSettings::GetSettings(Player);

		if(SingingSettings == nullptr)
		{
			return EHazeActivationPointStatusType::Invalid;
		}
		
		if(Query.DistanceType == EHazeActivationPointDistanceType::Selectable || Query.DistanceType == EHazeActivationPointDistanceType::Selectable)
		{
			FVector ClosestPoint;
			if(FindClosestPointOnImpact(Player, this, ClosestPoint))
			{
				if(IsPointInsideCone(Player, ClosestPoint))
				{
					return EHazeActivationPointStatusType::Valid;
				}
			}
		}
		else if(Query.DistanceType == EHazeActivationPointDistanceType::Visible)
		{
			return EHazeActivationPointStatusType::Valid;
		}
		
		return EHazeActivationPointStatusType::Invalid;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, const FHazeQueriedActivationPointWithWidgetInformation& Query) const
	{
		if(bPowerfulSongImpactDisabled)
		{
			return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		return EHazeActivationPointStatusType::Valid;
	}

	void PowerfulSongImpact(FPowerfulSongInfo Info)
	{
		if(bPowerfulSongImpactDisabled)
		{
			return;
		}

		OnPowerfulSongImpact.Broadcast(Info);
	}

	UFUNCTION(NetFunction)
	void NetPowerfulSongImpact(FPowerfulSongInfo Info)
	{
		if(bPowerfulSongImpactDisabled)
		{
			return;
		}
		
		OnPowerfulSongImpact.Broadcast(Info);
	}

	// This impact will no longer respond to any impact events or display the icon.
	UFUNCTION()
	void DisablePowerfulSongImpact()
	{
		bPowerfulSongImpactDisabled = true;
	}
}

namespace PowerfulSongStatics
{
	bool HasFreeSight(AActor Source, AActor Target, const FVector& StartLocation, const FVector& EndLocation)
	{
		EDrawDebugTrace DrawDebug = EDrawDebugTrace::None;

		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Source);
		IgnoreActors.Add(Game::GetMay());
		IgnoreActors.Add(Game::GetCody());
		
		{
			TArray<EObjectTypeQuery> ObjectTypes;
			ObjectTypes.Add(EObjectTypeQuery::WorldDynamic);
			ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);

			TArray<FHitResult> OutHits;

			System::LineTraceMultiForObjects(StartLocation, EndLocation, ObjectTypes, false, IgnoreActors, DrawDebug, OutHits, false);

			for(const FHitResult& Hit : OutHits)
			{
				UDEPRECATED_PowerfulSongImpactComponent PowerfulSongImpact = UDEPRECATED_PowerfulSongImpactComponent::Get(Hit.Actor);

				if(PowerfulSongImpact != nullptr && !PowerfulSongImpact.bBlockPowerfulSong)
				{
					IgnoreActors.Add(PowerfulSongImpact.GetOwner());
				}
			}
		}

		FHitResult Hit;
		const bool bHit = System::LineTraceSingle(StartLocation, EndLocation, ETraceTypeQuery::Visibility, false, IgnoreActors, DrawDebug, Hit, false);

		return !bHit || Hit.Actor == Target;
	}
}
