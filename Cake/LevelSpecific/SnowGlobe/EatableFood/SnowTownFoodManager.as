import Cake.LevelSpecific.SnowGlobe.EatableFood.SnowTownFood;

class ASnowTownFoodManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<ASnowTownFood> TownFood;

	UPROPERTY(Category = "Setup")
	TArray<AHazeProp> FoodProps; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ASnowTownFood Food : TownFood)
		{
			if (!Food.IsActorDisabled())
				Food.DisableActor(this);
		}

		for (AHazeProp Prop : FoodProps)
		{
			if (!Prop.IsActorDisabled())
				Prop.DisableActor(this);
		}
	}

	UFUNCTION()
	void EnableFood()
	{
		for (ASnowTownFood Food : TownFood)
		{
			if (Food.IsActorDisabled())
				Food.EnableActor(this);
		}
	
		for (AHazeProp Prop : FoodProps)
		{
			if (Prop.IsActorDisabled())
				Prop.EnableActor(this);
		}
	}
}