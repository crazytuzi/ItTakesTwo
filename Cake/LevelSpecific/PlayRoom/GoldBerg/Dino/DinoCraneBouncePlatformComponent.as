import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtableComponent;

class UDinoCraneBouncePlatformComponent : UHeadButtableComponent
{
	UFUNCTION()
	void StartBounce()
	{
		StartedBounce();
	}

	UFUNCTION(BlueprintEvent)
	void StartedBounce()
	{

	}

	UFUNCTION()
	void EndBounce()
	{
		
	}
}