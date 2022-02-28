import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalTags;
import Peanuts.Aiming.AutoAimTarget;
import Cake.LevelSpecific.Music.Cymbal.CymbalSettings;
import Cake.LevelSpecific.Music.MusicWeaponTargetingComponent;

import ACymbal GetCymbalActor() from "Cake.LevelSpecific.Music.Cymbal.CymbalComponent";

#if !RELEASE
const FConsoleVariable CVar_CymbalDebugDraw("Music.CymbalDebugDraw", 0);
#endif // !RELEASE

settings CymbalDefaultSettings for UCymbalSettings
{
	CymbalDefaultSettings.MovementSpeed = 2000.0f;
}

struct FCymbalCollisionInfo
{
	AActor HitActor;
	UPrimitiveComponent HitComponent;
	FVector HitLocation;
	bool bBlockingHit = false;
}

enum ECymbalTrailVFXType
{
	Indoor,
	Outdoor
}

enum ECymbalState
{
	StartThrow,
	Moving,
	ReturnToOwner,
	AttachedToObject,
	AttachToOwner,
	Equipped
}

UFUNCTION()
void SetCymbalTrailVFX(ECymbalTrailVFXType TrailType)
{
	ACymbal Cymbal = GetCymbalActor();

	if(Cymbal != nullptr)
	{
		if(TrailType == ECymbalTrailVFXType::Indoor)
			Cymbal.SetVFXTrailToIndoor();
		else if(TrailType == ECymbalTrailVFXType::Outdoor)
			Cymbal.SetVFXTrailToOutdoor();
	}
}

class UCymbalHitVFXComponent : UActorComponent
{
	UPROPERTY()
	UNiagaraSystem CymbalImpactVFX = nullptr;
}

UCLASS(Abstract)
class ACymbal : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent CymbalMesh;
	default CymbalMesh.CollisionProfileName = n"NoCollision";
	default CymbalMesh.AddTag(ComponentTags::HideOnCameraOverlap);

	default CymbalMesh.ShadowPriority = EShadowPriority::ImportantShadow;
	default CymbalMesh.bReceiveWorldShadows = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactEffect;

	UPROPERTY(DefaultComponent)
	UMusicWeaponTargetingComponent TargetingComponent;

	UPROPERTY(Category = VFX)
	UNiagaraSystem IndoorTrailVFX;

	UPROPERTY(Category = VFX)
	UNiagaraSystem OutdoorTrailVFX;

	private UNiagaraSystem _CurrentTrailSystem;
	UNiagaraSystem GetCurrentTrailSystem() const property { return _CurrentTrailSystem; }

	FVector TargetLocation;

	bool bAttachedToObject = false;
	bool bAttachedToOwner = false;

	bool bCanAttachToObjects = true;
	bool bReturnToOwner = false;
	bool bIsMoving = false;
	
	int IsMovingCounter = 0;
	int ShowTrailEffectCounter = 0;

	bool bDebugDrawMovement = false;

	// This is only visual
	UPROPERTY(Category = Movement)
	float RotationSpeed = 1200.0f;

	// Value for reading the current movement speed including applied acceleration. Set from CymbalMovementCapability.
	float CurrentMovementSpeed = 0.0f;

	UCymbalImpactComponent AutoAimTarget = nullptr;
	UCymbalImpactComponent CurrentCymbalImpactComp;
	TArray<UNiagaraComponent> Trails;

	// Objects that this cymbal has been attached to since it was thrown. Will reset each throw.
	TArray<AActor> AttachedObjects;

	// Actors that have been hit, so we dont call a hit one them multiple times. This is reset every time the player throws the cymbal.
	TArray<AActor> HitObjects;

	TArray<EObjectTypeQuery> CachedObjectTypeQueries;

	UPROPERTY(Category = Settings)
	UCymbalSettings Settings = CymbalDefaultSettings;

	AHazePlayerCharacter OwnerPlayer;
	AActor AttachObject = nullptr;
	FVector AttachLocation;
	FVector StartLocation;
	FVector HitLocation;

	//ECymbalState CymbalState = ECymbalState::Equipped;

	void ClearAttachToObject()
	{
		AttachObject = nullptr;
		AttachLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CachedObjectTypeQueries.Add(EObjectTypeQuery::WorldDynamic);
		CachedObjectTypeQueries.Add(EObjectTypeQuery::WorldStatic);

		ApplyDefaultSettings(Settings);
		_CurrentTrailSystem = IndoorTrailVFX;
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Cymbal Throw"))
	void BP_OnCymbalThrow(UNiagaraSystem TrailVFX) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Cymbal Catch"))
	void BP_OnCymbalCatch() {}

	void AddCymbalCapabilities()
	{
		AddCapability(n"CymbalMovementCapability");
		AddCapability(n"CymbalAutoAimMovementCapability");

		AddDebugCapability(n"CymbalDebugCapability");
	}

	void SetTrailVisibility(bool bShow)
	{
		int OldShowTrailEffectCounter = ShowTrailEffectCounter;
		ShowTrailEffectCounter = (bShow ? ShowTrailEffectCounter + 1 : ShowTrailEffectCounter - 1);

		if(OldShowTrailEffectCounter <= 0 && ShowTrailEffectCounter > 0)
		{
			for (UNiagaraComponent CurTrail : Trails)
			{
				CurTrail.Activate();
			}
		}
		else if(OldShowTrailEffectCounter > 0 && ShowTrailEffectCounter <= 0)
		{
			for (UNiagaraComponent CurTrail : Trails)
			{
				CurTrail.Deactivate();
			}
		}
	}

	void OnCymbalHit(UCymbalImpactComponent Impact, UPrimitiveComponent HitComponent, FVector HitLocation, FVector Direction, bool bAutoAimHit)
	{
		FCymbalHitInfo HitInfo;
		HitInfo.bAutoAimHit = bAutoAimHit;
		HitInfo.Owner = this;
		HitInfo.Instigator = OwnerPlayer;
		HitInfo.DeltaMovement = Direction;
		HitInfo.HitLocation = HitLocation;
		HitInfo.HitComponent = HitComponent;
		Impact.CymbalHit(HitInfo);
	}

	UFUNCTION(NetFunction)
	void NetOnCymbalHit(UCymbalImpactComponent Impact, UPrimitiveComponent HitComponent, FVector HitLocation, FVector Direction, bool bAutoAimHit)
	{
		FCymbalHitInfo HitInfo;
		HitInfo.bAutoAimHit = bAutoAimHit;
		HitInfo.Owner = this;
		HitInfo.Instigator = OwnerPlayer;
		HitInfo.DeltaMovement = Direction;
		HitInfo.HitLocation = HitLocation;
		HitInfo.HitComponent = HitComponent;
		Impact.CymbalHit(HitInfo);
	}

	void PlayImpactVFX(FVector FacingDirection, UCymbalHitVFXComponent VFXOverridComp) const
	{
		PlayImpactVFX(FacingDirection.Rotation(), VFXOverridComp);
	}

	void PlayImpactVFX(FRotator FacingRotation, UCymbalHitVFXComponent VFXOverridComp) const
	{
		if(VFXOverridComp != nullptr && VFXOverridComp.CymbalImpactVFX != nullptr)
			Niagara::SpawnSystemAtLocation(VFXOverridComp.CymbalImpactVFX, ActorCenterLocation, FacingRotation);
		else if(ImpactEffect != nullptr)
			Niagara::SpawnSystemAtLocation(ImpactEffect, ActorCenterLocation, FacingRotation);
	}

	void SetVFXTrailToIndoor()
	{
		_CurrentTrailSystem = IndoorTrailVFX;
	}

	void SetVFXTrailToOutdoor()
	{
		_CurrentTrailSystem = OutdoorTrailVFX;
	}

	bool IsMoving() const
	{
		return IsMovingCounter > 0;
	}

	void SetIsMoving(bool bValue)
	{
		IsMovingCounter = bValue ? IsMovingCounter + 1 : IsMovingCounter - 1;
	}

	bool IsOverlappingOwnerPlayer() const
	{
		return IsOverlappingActor(Owner);
	}
}
