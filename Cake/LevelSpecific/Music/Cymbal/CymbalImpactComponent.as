import Cake.LevelSpecific.Music.Cymbal.CymbalSettings;
import UCymbalSettings GetCymbalSettingsFromPlayer(AHazePlayerCharacter) from "Cake.LevelSpecific.Music.Cymbal.CymbalComponent";
import bool ThrowCymbalWithoutAim(AActor) from "Cake.LevelSpecific.Music.Cymbal.CymbalComponent";
import bool IsCymbalEquipped(AActor) from "Cake.LevelSpecific.Music.Cymbal.CymbalComponent";
import Peanuts.Aiming.AutoAimStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalHitInfo;
import Cake.LevelSpecific.Music.MusicImpactComponent;

event void FOnCymbalHit(FCymbalHitInfo HitInfo);
event void FOnCymbalRemoved();

enum ECymbalImpactIconVisibilityType
{
	Always,
	OnlyDuringAiming,
	OnlyDuringNotAiming,
}

class UCymbalImpactComponent : UMusicImpactComponent
{
	default BiggestDistanceType = EHazeActivationPointDistanceType::Targetable;
	default ValidationType = EHazeActivationPointActivatorType::Cody;

	default WidgetClass = Asset("/Game/Blueprints/LevelSpecific/Music/Cymbal/WBP_CymbalWidget.WBP_CymbalWidget_C");

	UPROPERTY()
	bool bPlayVFXOnHit = true;

	UPROPERTY()
	FOnCymbalHit OnCymbalHit;

	UPROPERTY()
	FOnCymbalRemoved OnCymbalRemoved;

	// Hides the icon, but impacts can still trigger if hit by collision.
	UPROPERTY(Category = Attribute)
	bool bHideCymbalWidget = false;

	bool bCymbalImpactEnabled = true;

	void SetCymbalImpactEnabled(bool bInValue)
	{
		bCymbalImpactEnabled = bInValue;
		if(!bInValue)
			ChangeValidActivator(EHazeActivationPointActivatorType::None);
		else
			ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, const FHazeQueriedActivationPointWithWidgetInformation& Query) const
	{
		if(bHideCymbalWidget)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
	{	
		if(!bCymbalImpactEnabled)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(!IsCymbalEquipped(Player))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		return Super::SetupActivationStatus(Player, Query);
	}

	UFUNCTION(BlueprintOverride)
	float SetupGetDistanceForPlayer(AHazePlayerCharacter Player, EHazeActivationPointDistanceType Type) const
	{
		UCymbalSettings CymbalSettings = GetCymbalSettingsFromPlayer(Player);

		if(CymbalSettings == nullptr)
		{
			return GetDistance(Type);
		}

		const float CymbalDistance = CymbalSettings.MovementDistanceMaximum;

		if(Type == EHazeActivationPointDistanceType::Selectable)
		{
			return CymbalDistance;
		}
		else if(Type == EHazeActivationPointDistanceType::Targetable)
		{
			return CymbalDistance;
		}
		else if(Type == EHazeActivationPointDistanceType::Visible)
		{
			return CymbalDistance * 1.5;
		}

		return GetDistance(Type);
	}

	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		if(!bCymbalImpactEnabled)
			return;
		
		OnCymbalHit.Broadcast(HitInfo);
		Game::GetCody().SetCapabilityActionState(n"AudioOnCymbalHit", EHazeActionState::ActiveForOneFrame);
	}

	void CymbalRemoved()
	{
		OnCymbalRemoved.Broadcast();
	}

	bool RequiresAiming(AHazePlayerCharacter Player) const
	{
		return !ThrowCymbalWithoutAim(Player);
	}
}