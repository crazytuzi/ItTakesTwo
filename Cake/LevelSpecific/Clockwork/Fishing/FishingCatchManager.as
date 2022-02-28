import Cake.LevelSpecific.Clockwork.Fishing.FishingCatchObject;

class AFishingCatchManager : AHazeActor
{
	UPROPERTY()
	TArray<AFishingCatchObject> CatchObjectArray;

	UPROPERTY()
	TArray<AFishingCatchObject> CatchObjectInuseArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AFishingCatchObject CatchObj : CatchObjectArray)
		{
			DisableCaughtObj(CatchObj);
		}
	}
	
	UFUNCTION()
	void DisableCaughtObj(AFishingCatchObject CatchObj)
	{
		if (CatchObj == nullptr)
			return;

		CatchObj.bCanRotateMesh = false;

		if (!CatchObj.IsActorDisabled(this))
			CatchObj.DisableActor(this);
	}

	AFishingCatchObject EnableCaughtObj(int Index)
	{
		if (CatchObjectArray[Index].IsActorDisabled())
			CatchObjectArray[Index].EnableActor(this);

		AFishingCatchObject NewCaught = CatchObjectArray[Index];
		// CatchObjectArray.Remove(CatchObjectArray[Index]);CatchObjectArray

		return NewCaught;
	}
}