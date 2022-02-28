import Cake.Weapons.Sap.SapAttachTarget;
import Cake.Weapons.Sap.SapWeaponSettings;

event void FOnSapMassAdded(FSapAttachTarget Where, float Mass);
event void FOnSapMassRemoved(FSapAttachTarget Where, float Mass);
event void FOnSapExploded(FSapAttachTarget Where, float Mass);
event void FOnSapExplodedProximity(FSapAttachTarget Where, float Mass, float Distance);
event void FOnSapHitNonStick(FSapAttachTarget Where, float Mass);
event void FOnSapConsumed(FSapAttachTarget Where, float Mass);

class USapResponseComponent : UActorComponent
{
	UPROPERTY(Category = "SapBehaviour")
	bool bEnableSapAutoAim = true;

	UPROPERTY(Category = "SapBehaviour")
	bool bOverrideSapAutoAimAngle = false;

	// How much matches can auto-aim onto the saps attached to this response-actor
	UPROPERTY(Category = "SapBehaviour", meta=(EditCondition="bOverrideSapAutoAimAngle"))
	float SapAutoAimAngle = 15.f;

	UPROPERTY(Category = "SapBehaviour")
	bool bOverrideSapSpeed = false;

	// A custom lob-height for sap trajectories. Lower lob height means quicker saps.
	UPROPERTY(Category = "SapBehaviour")
	float CustomSapSpeed = 5000.f;

	UPROPERTY(meta = (NotBlueprintCallable))
	FOnSapMassAdded OnMassAdded;

	UPROPERTY(meta = (NotBlueprintCallable))
	FOnSapMassRemoved OnMassRemoved;

	UPROPERTY(meta = (NotBlueprintCallable))
	FOnSapExploded OnSapExploded;

	UPROPERTY(meta = (NotBlueprintCallable))
	FOnSapExplodedProximity OnSapExplodedProximity;

	UPROPERTY(meta = (NotBlueprintCallable))
	FOnSapHitNonStick OnHitNonStick;

	UPROPERTY(meta = (NotBlueprintCallable))
	FOnSapConsumed OnSapConsumed;

	void CallOnExplodeProximity(FSapAttachTarget Where, float Mass, float Distance)
	{
		// May decides what is being exploded and how :)
		if (!Game::May.HasControl())
			return;

		NetCallOnExplodeProximity(Where, Mass, Distance);
	}
	UFUNCTION(NetFunction)
	void NetCallOnExplodeProximity(FSapAttachTarget Where, float Mass, float Distance)
	{
		OnSapExplodedProximity.Broadcast(Where, Mass, Distance);
	}
}