local C={}
C.Store="GorpsEvolution_v1"
-- Keep persisted player-to-player trades closed until GE-TRADE-01 has a
-- crash-recoverable journal. Studio profiles are unsaved and remain testable.
C.DurableTrades=false
C.Resources={Wood=3,Stone=5,Iron=12,Meat=7,Berries=4,Crystal=35,Fiber=3}
C.Nodes={Tree={"Wood",3,12},Rock={"Stone",2,14},Ore={"Iron",2,20},Bush={"Berries",3,10},Crystal={"Crystal",1,40},Fiber={"Fiber",3,12},Wild={"Meat",3,25}}
C.Species={
Gorp={role="Support",hp=100,attack=12,speed=12,color={82,203,151},rarity="Common"},
Shade={role="Assassin",hp=65,attack=25,speed=22,color={157,112,216},rarity="Uncommon"},
Boulder={role="Tank",hp=220,attack=19,speed=7,color={202,143,100},rarity="Uncommon"},
Bloom={role="Support",hp=90,attack=10,speed=12,color={249,158,187},rarity="Rare"},
Carrier={role="Transport",hp=150,attack=9,speed=24,color={247,204,112},rarity="Common"},
Mole={role="Miner",hp=115,attack=13,speed=9,color={134,157,202},rarity="Common"},
Dart={role="Ranged",hp=75,attack=20,speed=17,color={107,211,221},rarity="Rare"}}
C.SpeciesOrder={"Gorp","Shade","Boulder","Bloom","Carrier","Mole","Dart"}
C.Rarities={"Common","Uncommon","Rare","Epic","Legendary"}
C.Recipes={FenceKit={cost={Wood=14,Stone=5},grant={FenceKit=1},level=1},FeedPack={cost={Meat=2,Berries=3,Fiber=1},grant={FeedPack=2},level=1},Alloy={cost={Iron=5,Stone=5},grant={Alloy=1},level=2},EggIncubator={cost={Iron=10,Crystal=2,Alloy=2},grant={EggIncubator=1},level=3}}
C.Shop={FoodCrate={price=80,grant={Meat=8,Berries=12}},ExpeditionKit={price=160,grant={Wood=15,Stone=12,Iron=5}},DecorationLamp={price=250,grant={DecorationLamp=1}},CrystalBundle={price=450,grant={Crystal=5}}}
C.Workers={Farmer={price=150,wage=8,grant={Berries=4,Meat=1}},Miner={price=230,wage=12,grant={Stone=3,Iron=1}},Caretaker={price=180,wage=10,grant={Meat=2,Fiber=2}}}
C.Quests={Gatherer={goal=15,reward=70},Provider={goal=3,reward=90},Maker={goal=2,reward=110},Employer={goal=1,reward=130},Explorer={goal=5,reward=150}}
C.Eggs={
 Meadow={title="Meadow Egg",price=100,pool={
  {species="Gorp",weight=45},{species="Mole",weight=30},
  {species="Carrier",weight=20},{species="Bloom",weight=5}
 }},
 Wild={title="Wild Egg",price=280,pool={
  {species="Shade",weight=35},{species="Boulder",weight=30},
  {species="Dart",weight=25},{species="Bloom",weight=10}
 }}
}
C.EggOrder={"Meadow","Wild"}
return C
