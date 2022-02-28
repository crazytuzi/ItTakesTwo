import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspBlasterBolt;

class UWaspShootyTeam : UHazeAITeam
{
    private TSet<AWaspBlasterBolt> WaspBlasterBoltPool;
    
    AWaspBlasterBolt GetAvailableBlasterBolt()
    {
        for (AWaspBlasterBolt Bolt : WaspBlasterBoltPool)
        {
            if (Bolt.IsAvailable())
                return Bolt;
        }
        if (WaspBlasterBoltPool.Num() < 30)
        {
            // Spawn a new bolt
            AWaspBlasterBolt NewBolt = Cast<AWaspBlasterBolt>(SpawnActor(AWaspBlasterBolt::StaticClass()));
            WaspBlasterBoltPool.Add(NewBolt);
			NewBolt.MakeNetworked(this, WaspBlasterBoltPool.Num());
            return NewBolt;
        }
        return nullptr;
    }

}