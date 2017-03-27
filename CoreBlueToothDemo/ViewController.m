//
//  ViewController.m
//  CoreBlueToothDemo
//
//  Created by xqzh on 17/3/24.
//  Copyright © 2017年 xqzh. All rights reserved.
//

#import "ViewController.h"

#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property (nonatomic, strong) CBCentralManager *centralManager; // 中心管理者
@property (nonatomic, strong) NSMutableArray *peripherals; // 外设数组
@property (nonatomic, strong) CBPeripheral *peripheral; // 外设
@property (nonatomic, strong) CBCharacteristic *characteristic; // 特征

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.peripherals = [NSMutableArray array];
  
  // 队列
  dispatch_queue_t centralQueue = dispatch_queue_create("central", DISPATCH_QUEUE_SERIAL);
  // 中心管理
  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue];
  
  
}


#pragma mark - centralManager delegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
  NSLog(@"name:%@",peripheral);
  if (!peripheral || !peripheral.name || ([peripheral.name isEqualToString:@""])) {
    return;
  }
  if ([self.peripherals containsObject:peripheral]) {
    return;
  }
  
  [self.peripherals addObject:peripheral];
  
  [self performSelectorOnMainThread:@selector(updateTableView) withObject:nil waitUntilDone:YES];
  
  if (!self.peripheral || (self.peripheral.state == CBPeripheralStateDisconnected)) {
    self.peripheral = peripheral;
    self.peripheral.delegate = self;
    NSLog(@"connect peripheral");
//    [self.centralManager connectPeripheral:peripheral options:nil];
  }
}

- (void)updateTableView {
  [self.tableView reloadData];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  if (!peripheral) {
    return;
  }
  
  [self.centralManager stopScan];
  
  NSLog(@"peripheral did connect");
  [self.peripheral discoverServices:nil];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
  // 寻找外设
  [self.centralManager scanForPeripheralsWithServices:@[] options:nil];
}

#pragma mark - peripheral delegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  NSArray *services = nil;
  
  if (peripheral != self.peripheral) {
    NSLog(@"Wrong Peripheral.\n");
    return ;
  }
  
  if (error != nil) {
    NSLog(@"Error %@\n", error);
    return ;
  }
  
  services = [peripheral services];
  if (!services || ![services count]) {
    NSLog(@"No Services");
    return ;
  }
  
  for (CBService *service in services) {
    NSLog(@"service:%@",service.UUID);
    [peripheral discoverCharacteristics:nil forService:service];
    
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
  NSLog(@"characteristics:%@",[service characteristics]);
  NSArray *characteristics = [service characteristics];
  
  if (peripheral != self.peripheral) {
    NSLog(@"Wrong Peripheral.\n");
    return ;
  }
  
  if (error != nil) {
    NSLog(@"Error %@\n", error);
    return ;
  }
  
  self.characteristic = [characteristics firstObject];
  [self.peripheral readValueForCharacteristic:self.characteristic];
  [self.peripheral setNotifyValue:YES forCharacteristic:self.characteristic];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
  NSData *data = characteristic.value;
  NSLog(@"%@", data);
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
  }
  
  CBPeripheral *peripheral = self.peripherals[indexPath.row];
  
  cell.textLabel.text = peripheral.name;
  
  return cell;
}


@end
