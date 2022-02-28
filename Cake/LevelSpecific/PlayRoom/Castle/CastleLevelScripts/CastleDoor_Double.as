import Cake.LevelSpecific.PlayRoom.Castle.CastleLevelScripts.CastleDoor;

class ACastleDoorDouble : ACastleDoor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorPivotOther;

	UPROPERTY(DefaultComponent, Attach = DoorPivotOther)
	UStaticMeshComponent DoorMeshOther;

	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ACastleDoor::ConstructionScript();

		if (bStartOpen)
		{
			FRotator NewRotation = FRotator(DoorPivotOther.RelativeRotation.Pitch, -RotationDegrees, DoorPivotOther.RelativeRotation.Roll);
			DoorPivotOther.SetRelativeRotation(NewRotation);
		}
		else
		{
			DoorPivotOther.SetRelativeRotation(FRotator::ZeroRotator);		
		}
	}

	UFUNCTION()
	void OnDoorMovementUpdate(float CurrentValue)
	{
		ACastleDoor::OnDoorMovementUpdate(CurrentValue);		

		float NewYaw = FMath::Lerp(0.f, -RotationDegrees, CurrentValue);
		FRotator NewRotation = FRotator(DoorPivotOther.RelativeRotation.Pitch, NewYaw, DoorPivotOther.RelativeRotation.Roll);

		DoorPivotOther.SetRelativeRotation(NewRotation);
	}
}