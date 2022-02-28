import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

class UWheelBoatAvoidPointComponent : UActorComponent
{
	UPROPERTY(Category = "Setup")
	bool bIsActive;

	TArray<AWheelBoatActor> WheelBoatArray;
	AWheelBoatActor WheelBoat;

	UFUNCTION()
	void ActivateAvoidPoint(float AvoidTime, float AvoidForce, float Radius)
	{
		if (!bIsActive)
			return;

		if (WheelBoat == nullptr)
		{
			GetAllActorsOfClass(WheelBoatArray);
			
			if (WheelBoatArray.Num() > 0)
				WheelBoat = WheelBoatArray[0];
		}
		
		if (WheelBoat != nullptr)
			WheelBoat.AvoidPoint.Setup(Owner.GetActorLocation(), Radius, AvoidForce, 2000.f, 3.f);

		if(AvoidForce >= 0)
			System::SetTimer(this, n"DeactivateAvoidPoint", AvoidTime, false);
	}

	UFUNCTION()
	void DeactivateAvoidPoint()
	{
		if (!bIsActive)
			return;

		if (WheelBoat == nullptr)
		{
			GetAllActorsOfClass(WheelBoatArray);
			
			if (WheelBoatArray.Num() > 0)
				WheelBoat = WheelBoatArray[0];
		}

		if (WheelBoat != nullptr)
			WheelBoat.AvoidPoint.Clear();
	}
}